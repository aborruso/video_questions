"""vq - video questions: answer questions about YouTube videos with LLM."""

import json
import re
import shutil
import subprocess
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


app = typer.Typer(help="Query YouTube videos with LLM.", add_completion=False)
console = Console()

CACHE_DIR = Path(tempfile.gettempdir()) / "qv_cache"
CACHE_DAYS = 60


def check_dependencies() -> None:
    for dep in ["yt-dlp"]:
        if not shutil.which(dep):
            console.print(f"[red]Error:[/red] {dep} is required but not installed.")
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
    # validate standard format
    if not re.match(r"^https://(www\.)?youtube\.com/watch\?v=[a-zA-Z0-9_-]{11}", url):
        console.print(
            "[red]Error:[/red] Invalid YouTube URL.\n"
            "Expected: https://www.youtube.com/watch?v=VIDEO_ID"
        )
        raise typer.Exit(1)
    return url


def get_video_id(url: str) -> str:
    r = subprocess.run(["yt-dlp", "--get-id", url], capture_output=True, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        console.print("[red]Error:[/red] Unable to extract video ID. Video may be private or unavailable.")
        raise typer.Exit(1)
    return r.stdout.strip()


def get_video_title(url: str) -> str:
    r = subprocess.run(["yt-dlp", "-q", "--skip-download", "--get-title", url], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def clean_subtitles(raw: str) -> str:
    lines = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        if re.match(r"^\d+$", line):
            continue
        if "-->" in line:
            continue
        if re.match(r"^\[.*\]$", line):
            continue
        if re.match(r"^WEBVTT", line) or re.match(r"^(Kind|Language):", line):
            continue
        line = re.sub(r"<[^>]+>", "", line)
        if line:
            lines.append(line)
    return " ".join(lines)


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
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()

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
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()

    # 3. Any auto-generated VTT
    for captions in auto_caps.values():
        for cap in captions:
            if cap.get("ext") == "vtt" and cap.get("url"):
                return cap["url"]

    console.print("[red]Error:[/red] No subtitles available for this video.")
    raise typer.Exit(1)


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
            console.print(f"[dim]Using cached subtitles[/dim]")
            title = title_file.read_text().strip() if title_file.exists() else ""
            return content, title

    console.print("[dim]Downloading subtitles...[/dim]")

    with Status("Fetching video info...", console=console):
        r = subprocess.run(["yt-dlp", "-j", url], capture_output=True, text=True)
        if r.returncode != 0:
            console.print("[red]Error:[/red] yt-dlp failed to fetch video info.")
            raise typer.Exit(1)
        info = json.loads(r.stdout)

    subtitle_url = get_subtitle_url(url, info)

    with Status("Downloading subtitle file...", console=console):
        resp = requests.get(subtitle_url, timeout=30)
        if not resp.ok or not resp.text.strip():
            console.print("[red]Error:[/red] Subtitle download failed.")
            raise typer.Exit(1)
        content = clean_subtitles(resp.text)

    if not content:
        console.print("[red]Error:[/red] Subtitle content is empty after processing.")
        raise typer.Exit(1)

    cache_file.write_text(content)
    console.print(f"[dim]Subtitles cached[/dim]")

    title = get_video_title(url)
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
    text_only: bool = typer.Option(False, "--text-only", help="Print subtitles and exit"),
    debug: bool = typer.Option(False, "--debug", help="Show debug info"),
    _version: bool = typer.Option(False, "--version", "-V", callback=_version_callback, is_eager=True, help="Show version and exit"),
) -> None:
    check_dependencies()

    if not question and not text_only and not template:
        console.print("[dim]No question provided — switching to --text-only mode.[/dim]")
        text_only = True

    url = normalize_url(url)

    with Status("Getting video ID...", console=console):
        video_id = get_video_id(url)

    content, title = load_subtitles(url, video_id, no_cache=no_cache)

    if len(content) < 100:
        console.print("[yellow]Warning:[/yellow] Subtitles seem unusually short. Results may be inaccurate.")

    # Save subtitles to file if requested
    if sub_file:
        if sub_file.exists():
            overwrite = typer.confirm(f"{sub_file} already exists. Overwrite?")
            if not overwrite:
                console.print("Cancelled.")
                raise typer.Exit(0)
        sub_file.write_text(content)
        console.print(f"[green]Subtitles saved to {sub_file}[/green]")

    if text_only:
        console.print(content)
        return

    # LLM processing
    system_parts = ["You are a helpful assistant that answers questions about YouTube videos."]
    if language:
        system_parts.append(f"Reply in {language}.")
    if title:
        system_parts.append(f"Video title: {title}")
    system_prompt = "\n".join(system_parts)

    full_prompt = f"{content}\n\n{question}"

    if debug:
        console.print(Panel(f"[bold]System prompt (first 200 chars):[/bold]\n{system_prompt[:200]}...", title="DEBUG"))
        console.print(Panel(f"[bold]Prompt (first 200 chars):[/bold]\n{full_prompt[:200]}...", title="DEBUG"))

    if title:
        console.print(Panel(f"[bold]{title}[/bold]", subtitle=url, style="blue"))

    console.print()

    # Build llm CLI command — uses system llm with all user plugins/models
    if not shutil.which("llm"):
        console.print("[red]Error:[/red] llm is not installed or not in PATH.")
        raise typer.Exit(1)

    if template:
        cmd = ["llm", "-t", template, full_prompt]
    else:
        cmd = ["llm", "-s", system_prompt, full_prompt]

    if model:
        cmd = cmd[:1] + ["-m", model] + cmd[1:]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Stream stdout with live Markdown rendering
    full_text = ""
    with Live(Markdown(""), console=console, refresh_per_second=8) as live:
        for char in iter(lambda: process.stdout.read(1), ""):
            full_text += char
            live.update(Markdown(full_text))

    process.wait()
    if process.returncode != 0:
        err = process.stderr.read()
        console.print(f"[red]Error:[/red] llm failed. {err}")
        raise typer.Exit(1)

    if output:
        output.write_text(full_text)
        console.print(f"[green]Response saved to {output}[/green]")


if __name__ == "__main__":
    app()
