# vq — video questions

Answer questions about YouTube videos using subtitles and an LLM.

`vq` fetches subtitles from a YouTube video, passes them to an LLM, and returns the answer — with live Markdown rendering in the terminal.

## Requirements

`vq` shells out to two external CLIs that must be on your `PATH`:

- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) — subtitle extraction (always required)
- [`llm`](https://llm.datasette.io/) — LLM integration (required to answer questions; not needed for `--text-only`/`--metadata`)

`vq` checks these at startup and, if one is missing, prints the missing tool with an install hint and exits.

Install them as standalone tools (recommended, keeps your `llm` plugins/keys):

```bash
uv tool install yt-dlp
uv tool install llm
```

### YouTube: keep `yt-dlp` current + JS runtime

Since 2026 YouTube requires `yt-dlp` to solve a JavaScript challenge, otherwise it
returns a misleading `This video is not available` for videos that are perfectly
fine. Two things are needed:

1. A **recent** `yt-dlp` (older than ~90 days often breaks):

   ```bash
   uv tool upgrade yt-dlp   # or: pipx upgrade yt-dlp
   ```

2. A **JavaScript runtime** (`deno`) plus the EJS challenge-solver script:

   ```bash
   curl -fsSL https://deno.land/install.sh | sh   # installs deno to ~/.deno/bin
   ```

   Then enable it once, globally, in `~/.config/yt-dlp/config`:

   ```
   --js-runtimes deno:/home/YOU/.deno/bin/deno
   --remote-components ejs:github
   ```

   (`--remote-components ejs:github` lets `yt-dlp` fetch the challenge solver on
   demand. This affects every `yt-dlp` call on your machine, not just `vq`.)

If `vq` prints `yt-dlp failed to fetch video info`, run the failing URL through
`yt-dlp -j <URL>` directly — `vq` now echoes yt-dlp's own error underneath, which
tells you the real cause.

You also need [`uv`](https://docs.astral.sh/uv/) to install `vq` itself:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## LLM Configuration

Before first use, configure an API key for your preferred provider:

**OpenAI:**

```bash
llm keys set openai
```

**Anthropic (Claude):**

```bash
llm install llm-anthropic
llm keys set anthropic
```

For other providers, see the [LLM plugins directory](https://llm.datasette.io/en/stable/plugins/directory.html).

## Installation

**From PyPI (recommended)** — the package is published as `video-questions`; the installed command is `vq`:

```bash
uv tool install video-questions
```

<details>
<summary>Alternatives (pipx / pip)</summary>

```bash
pipx install video-questions
# or, into the current environment:
pip install video-questions
```

</details>

**Upgrade:**

```bash
uv tool upgrade video-questions
```

**Uninstall:**

```bash
uv tool uninstall video-questions
```

**From source:**

```bash
git clone https://github.com/aborruso/video_questions.git
cd video_questions
make install     # uv tool install .
make dev         # editable dev environment
make uninstall
```

## Verify Installation

```bash
make test
```

Or manually:

```bash
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only | head -5
```

## Usage

```
vq [OPTIONS] URL [QUESTION]
```

### Arguments

| Argument | Description |
|---|---|
| `URL` | YouTube URL (required). Supports standard, `youtu.be`, and Shorts URLs. |
| `QUESTION` | Question to ask about the video. If omitted, switches to `--text-only` mode. |

### Options

| Option | Description |
|---|---|
| `-p, --language TEXT` | Response language (e.g. `Italian`, `French`) |
| `-t, --template TEXT` | LLM [template](https://llm.datasette.io/en/stable/templates.html) name |
| `-m, --model TEXT` | LLM model to use (e.g. `gpt-4o`, `claude-3-5-sonnet-20241022`) |
| `--sub PATH` | Save subtitles to file |
| `-o, --output PATH` | Save LLM response to file |
| `-i, --chat` | After the answer, stay in an interactive follow-up session (continues via `llm -c`) |
| `--no-cache` | Skip cache, re-download subtitles |
| `--text-only` | Print subtitles and exit (no LLM) |
| `--metadata` | Print video metadata as one JSONL line and exit (no transcript) |
| `--debug` | Show debug info (system prompt and prompt preview) |
| `-V, --version` | Show version and exit |

## Examples

```bash
# Ask a question about a video
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics?'

# Ask, then keep asking interactively about the same video (-i / --chat)
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'Give me a summary' -i

# Reply in Italian
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -p Italian

# Use a specific model
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'Summarize this' -m claude-3-5-sonnet-20241022

# Use an LLM template
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -t my_template

# Save subtitles to file
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' --sub subtitles.txt

# Save LLM response to file
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'Summarize this' -o response.md

# Print subtitles only (no LLM)
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only

# Force re-download (skip cache)
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What changed?' --no-cache
```

## Cache

Subtitles are cached in `/tmp/qv_cache/` for 60 days.

```bash
# View cache
ls -lh /tmp/qv_cache/

# Clear all cache
rm -rf /tmp/qv_cache/

# Clear cache for a specific video
rm -f /tmp/qv_cache/VIDEO_ID.txt /tmp/qv_cache/VIDEO_ID.title.txt
```

Use `--no-cache` to force a fresh download without clearing the cache.
