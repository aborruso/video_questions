"""vq - video questions: answer questions about YouTube videos with LLM."""

import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
from importlib.metadata import version
from pathlib import Path

import requests
import typer
from rich.console import Console
from rich.live import Live
from rich.markdown import Markdown
from rich.panel import Panel
from rich.status import Status

__version__ = version("vq")

def _version_callback(value: bool) -> None:
    if value:
        console.print(f"vq {__version__}")
        raise typer.Exit()


app = typer.Typer(
    help="Answer questions about a YouTube video from its subtitles, via an LLM.",
    add_completion=False,
)
# console -> stdout: only the payload (subtitle text / LLM answer / --version).
# err_console -> stderr: all status, progress, warnings, errors and decorations,
# so stdout stays clean for pipes (`vq URL --text-only > file.txt`).
console = Console()
err_console = Console(stderr=True)

CACHE_DIR = Path(tempfile.gettempdir()) / "qv_cache"
CACHE_DAYS = 60


def check_dependencies() -> None:
    for dep in ["yt-dlp"]:
        if not shutil.which(dep):
            err_console.print(f"[red]Error:[/red] {dep} is required but not installed.")
            raise typer.Exit(1)


def normalize_url(url: str) -> str:
    # shorts
    m = re.match(r"^https://(www\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11})", url)
    if m:
        return f"https://www.youtube.com/watch?v={m.group(2)}"
    # youtu.be
    m = re.match(r"^https://youtu\.be/([a-zA-Z0-9_-]{11})", url)
    if m:
        return f"https://www.youtube.com/watch?v={m.group(1)}"
    # standard watch URL: keep only the video id, dropping extra params
    # (&list=, &t=, &pp=, ...) that would make yt-dlp resolve a *different*
    # video for --get-id vs -j and thus cache content under the wrong id.
    m = re.match(r"^https://(www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})", url)
    if m:
        return f"https://www.youtube.com/watch?v={m.group(2)}"
    err_console.print(
        "[red]Error:[/red] Invalid YouTube URL.\n"
        "Expected: https://www.youtube.com/watch?v=VIDEO_ID"
    )
    raise typer.Exit(1)


def get_video_id(url: str) -> str:
    # url is canonical (normalize_url), so the id is the v= param. Deriving it
    # here, instead of a separate `yt-dlp --get-id`, guarantees the cache key
    # matches the URL the subtitles are downloaded from.
    m = re.search(r"[?&]v=([a-zA-Z0-9_-]{11})", url)
    if not m:
        err_console.print("[red]Error:[/red] Unable to extract video ID from URL.")
        raise typer.Exit(1)
    return m.group(1)


def timestamp_to_seconds(ts: str) -> int:
    parts = ts.split(":")
    if len(parts) == 3:
        return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
    return int(parts[0]) * 60 + int(parts[1])


def linkify_timestamps(text: str, video_id: str) -> str:
    def replace(m):
        ts = m.group(0)
        secs = timestamp_to_seconds(ts)
        return f"{ts} (https://www.youtube.com/watch?v={video_id}&t={secs})"
    return re.sub(r"\b\d{1,2}:\d{2}(?::\d{2})?\b", replace, text)


def clean_subtitles(raw: str) -> str:
    lines = []
    last_content = None
    last_ts_secs = -60
    pending_ts = None

    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        if re.match(r"^\d+$", line):
            continue
        if "-->" in line:
            m = re.match(r"(\d+):(\d{2}):(\d{2})", line)
            if m:
                secs = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3))
                if secs - last_ts_secs >= 60:
                    pending_ts = secs
                    last_ts_secs = secs
            continue
        if re.match(r"^\[.*\]$", line):
            continue
        if re.match(r"^WEBVTT", line) or re.match(r"^(Kind|Language):", line):
            continue
        line = re.sub(r"<[^>]+>", "", line).strip()
        # YouTube auto-captions are "rolling": each cue re-shows the lines still
        # on screen plus the new portion, so every segment appears ~3x. Drop a
        # content line when it repeats the last one already emitted.
        if not line or line == last_content:
            continue
        if pending_ts is not None:
            lines.append(f"[{pending_ts // 60}:{pending_ts % 60:02d}]")
            pending_ts = None
        lines.append(line)
        last_content = line
    return " ".join(lines)


def _printed_url(r: subprocess.CompletedProcess) -> str | None:
    # yt-dlp --print emits the literal "NA" for missing fields; treat it (and
    # an empty/echoed template) as "no url" so we don't return a junk value.
    out = r.stdout.strip()
    if r.returncode != 0 or not out or out == "NA" or out.startswith("requested_subtitles."):
        return None
    return out


def get_subtitle_url(url: str, info: dict) -> str:
    auto_caps = info.get("automatic_captions", {})

    # 1. Original audio language
    orig_langs = [k.replace("-orig", "") for k in auto_caps if k.endswith("-orig")]
    for lang in orig_langs:
        r = subprocess.run(
            [
                "yt-dlp", "-q", "--skip-download", "--convert-subs", "srt",
                "--write-auto-sub", "--sub-langs", lang,
                "--print", f"requested_subtitles.{lang}.url", url,
            ],
            capture_output=True,
            text=True,
        )
        if _printed_url(r):
            return _printed_url(r)

    # 2. English
    r = subprocess.run(
        [
            "yt-dlp", "-q", "--skip-download", "--convert-subs", "srt",
            "--write-sub", "--sub-langs", "en",
            "--write-auto-sub", "--print", "requested_subtitles.en.url", url,
        ],
        capture_output=True,
        text=True,
    )
    if _printed_url(r):
        return _printed_url(r)

    # 3. Any auto-generated VTT
    for captions in auto_caps.values():
        for cap in captions:
            if cap.get("ext") == "vtt" and cap.get("url"):
                return cap["url"]

    err_console.print("[red]Error:[/red] No subtitles available for this video.")
    raise typer.Exit(1)


def get_info(url: str) -> dict:
    with Status("Fetching video info...", console=err_console):
        r = subprocess.run(["yt-dlp", "-j", url], capture_output=True, text=True)
        if r.returncode != 0:
            err_console.print("[red]Error:[/red] yt-dlp failed to fetch video info.")
            raise typer.Exit(1)
        return json.loads(r.stdout)


def build_metadata(info: dict, url: str) -> dict:
    # Curated, transcript-free view of the yt-dlp info dict (drops the heavy
    # formats/fragments/thumbnails arrays), suitable as one JSONL record.
    return {
        "id": info.get("id"),
        "url": info.get("webpage_url") or url,
        "title": info.get("title"),
        "description": info.get("description"),
        "channel": info.get("channel") or info.get("uploader"),
        "channel_id": info.get("channel_id"),
        "channel_url": info.get("channel_url") or info.get("uploader_url"),
        "duration": info.get("duration"),
        "duration_string": info.get("duration_string"),
        "upload_date": info.get("upload_date"),
        "view_count": info.get("view_count"),
        "like_count": info.get("like_count"),
        "comment_count": info.get("comment_count"),
        "language": info.get("language"),
        "tags": info.get("tags"),
        "categories": info.get("categories"),
        "thumbnail": info.get("thumbnail"),
        "subtitles": sorted(info.get("subtitles", {}).keys()),
        "has_automatic_captions": bool(info.get("automatic_captions")),
    }


def load_subtitles(url: str, video_id: str, no_cache: bool = False) -> tuple[str, str]:
    """Return (content, title), using cache when available."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    # Cleanup old cache files
    cutoff = time.time() - CACHE_DAYS * 86400
    for f in CACHE_DIR.glob("*"):
        if f.stat().st_mtime < cutoff:
            f.unlink(missing_ok=True)

    cache_file = CACHE_DIR / f"{video_id}.txt"
    title_file = CACHE_DIR / f"{video_id}.title.txt"

    if not no_cache and cache_file.exists():
        content = cache_file.read_text().strip()
        if content:
            err_console.print(f"[dim]Using cached subtitles[/dim]")
            title = title_file.read_text().strip() if title_file.exists() else ""
            return content, title

    err_console.print("[dim]Downloading subtitles...[/dim]")

    info = get_info(url)

    # Safety net: cache under the id of the video actually fetched, so the
    # filename can never disagree with its content (no poisoned cache).
    real_id = info.get("id") or video_id
    if real_id != video_id:
        cache_file = CACHE_DIR / f"{real_id}.txt"
        title_file = CACHE_DIR / f"{real_id}.title.txt"

    subtitle_url = get_subtitle_url(url, info)

    with Status("Downloading subtitle file...", console=err_console):
        try:
            resp = requests.get(subtitle_url, timeout=30)
        except requests.RequestException:
            err_console.print("[red]Error:[/red] Subtitle download failed.")
            raise typer.Exit(1)
        if not resp.ok or not resp.text.strip():
            err_console.print("[red]Error:[/red] Subtitle download failed.")
            raise typer.Exit(1)
        content = clean_subtitles(resp.text)

    if not content:
        err_console.print("[red]Error:[/red] Subtitle content is empty after processing.")
        raise typer.Exit(1)

    cache_file.write_text(content)
    err_console.print(f"[dim]Subtitles cached[/dim]")

    title = info.get("title") or ""
    if title:
        title_file.write_text(title)

    return content, title


@app.command()
def main(
    url: str = typer.Argument(..., help="YouTube URL"),
    question: str = typer.Argument(None, help="Question about the video"),
    language: str = typer.Option(None, "-p", "--language", help="Response language"),
    template: str = typer.Option(None, "-t", "--template", help="LLM template name"),
    model: str = typer.Option(None, "-m", "--model", help="LLM model to use"),
    sub_file: Path = typer.Option(None, "--sub", help="Save subtitles to file"),
    output: Path = typer.Option(None, "-o", "--output", help="Save LLM response to file"),
    no_cache: bool = typer.Option(False, "--no-cache", help="Skip cache, re-download subtitles"),
    text_only: bool = typer.Option(False, "--text-only", help="Print the cleaned transcript to stdout and exit (no LLM)"),
    metadata: bool = typer.Option(False, "--metadata", help="Print video metadata as one JSONL line (no transcript) and exit"),
    debug: bool = typer.Option(False, "--debug", help="Show debug info"),
    _version: bool = typer.Option(False, "--version", "-V", callback=_version_callback, is_eager=True, help="Show version and exit"),
) -> None:
    """
    Answer questions about a YouTube video from its subtitles.

    Fetches the video subtitles (cached 60 days), then feeds transcript +
    QUESTION to an LLM and streams a Markdown answer.

    Modes (stdout carries only the payload; status/errors go to stderr, so
    output is pipe-safe):

    \b
    - default:     vq URL "your question"   -> LLM answer (Markdown)
    - no question: vq URL                   -> prints the cleaned transcript
    - --text-only: vq URL --text-only       -> cleaned transcript, raw text
    - --metadata:  vq URL --metadata        -> one JSONL line of video
                   metadata (id, url, title, description, channel, duration,
                   upload_date, language, ...) and exit, NO transcript

    \b
    Examples:
      vq https://youtu.be/ID "what are the 3 main points?"
      vq https://youtu.be/ID --text-only > transcript.txt
      vq https://youtu.be/ID --metadata | jq .title
    """
    check_dependencies()

    url = normalize_url(url)

    if metadata:
        info = get_info(url)
        sys.stdout.write(json.dumps(build_metadata(info, url), ensure_ascii=False) + "\n")
        return

    if not question and not text_only and not template:
        err_console.print("[dim]No question provided — switching to --text-only mode.[/dim]")
        text_only = True

    with Status("Getting video ID...", console=err_console):
        video_id = get_video_id(url)

    content, title = load_subtitles(url, video_id, no_cache=no_cache)

    if len(content) < 100:
        err_console.print("[yellow]Warning:[/yellow] Subtitles seem unusually short. Results may be inaccurate.")

    # Save subtitles to file if requested
    if sub_file:
        if sub_file.exists():
            overwrite = typer.confirm(f"{sub_file} already exists. Overwrite?")
            if not overwrite:
                err_console.print("Cancelled.")
                raise typer.Exit(0)
        sub_file.write_text(content)
        err_console.print(f"[green]Subtitles saved to {sub_file}[/green]")

    if text_only:
        # raw write: no Rich wrapping/truncation to terminal width, so the
        # transcript survives pipes and redirects byte-for-byte.
        sys.stdout.write(content + "\n")
        return

    # LLM processing
    system_parts = [
        "You are a helpful assistant that answers questions about YouTube videos.",
        "Where relevant (not for every sentence), include the video timestamp in format M:SS or H:MM:SS so the user can verify.",
    ]
    if language:
        system_parts.append(f"Reply in {language}.")
    if title:
        system_parts.append(f"Video title: {title}")
    system_prompt = "\n".join(system_parts)

    full_prompt = f"{content}\n\n{question}"

    if debug:
        err_console.print(Panel(f"[bold]System prompt (first 200 chars):[/bold]\n{system_prompt[:200]}...", title="DEBUG"))
        err_console.print(Panel(f"[bold]Prompt (first 200 chars):[/bold]\n{full_prompt[:200]}...", title="DEBUG"))

    if title:
        err_console.print(Panel(f"[bold]{title}[/bold]", subtitle=url, style="blue"))

    err_console.print()

    # Build llm CLI command — uses system llm with all user plugins/models
    if not shutil.which("llm"):
        err_console.print("[red]Error:[/red] llm is not installed or not in PATH.")
        raise typer.Exit(1)

    if template:
        cmd = ["llm", "-t", template]
    else:
        cmd = ["llm", "-s", system_prompt]

    if model:
        cmd = cmd[:1] + ["-m", model] + cmd[1:]

    process = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    try:
        process.stdin.write(full_prompt)
        process.stdin.close()
    except BrokenPipeError:
        pass

    # Stream stdout with live Markdown rendering
    full_text = ""
    with Live(Markdown(""), console=console, refresh_per_second=8) as live:
        for chunk in iter(lambda: process.stdout.read(64), ""):
            full_text += chunk
            live.update(Markdown(full_text))
        process.wait()
        if process.returncode != 0:
            err = process.stderr.read()
            err_console.print(f"[red]Error:[/red] llm failed. {err}")
            raise typer.Exit(1)
        full_text = linkify_timestamps(full_text, video_id)
        live.update(Markdown(full_text))

    if output:
        output.write_text(full_text)
        err_console.print(f"[green]Response saved to {output}[/green]")


if __name__ == "__main__":
    app()
