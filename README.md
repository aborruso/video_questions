# vq — video questions

Answer questions about YouTube videos using subtitles and an LLM.

`vq` fetches subtitles from a YouTube video, passes them to an LLM, and returns the answer — with live Markdown rendering in the terminal.

## Requirements

- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) — subtitle extraction
- [`uv`](https://docs.astral.sh/uv/) — Python package manager
- [`llm`](https://llm.datasette.io/) — LLM integration (installed automatically)

Install `yt-dlp` and `uv`:

```bash
pip3 install yt-dlp
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

```bash
git clone https://github.com/aborruso/video_questions.git
cd video_questions
make install
```

**Uninstall:**

```bash
make uninstall
```

**Development environment:**

```bash
make dev
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
| `--no-cache` | Skip cache, re-download subtitles |
| `--text-only` | Print subtitles and exit (no LLM) |
| `--debug` | Show debug info (system prompt and prompt preview) |
| `-V, --version` | Show version and exit |

## Examples

```bash
# Ask a question about a video
vq 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics?'

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
