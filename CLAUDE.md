# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`vq` (video questions) is a Python CLI that fetches YouTube video subtitles and processes them with LLM to answer questions. It uses `yt-dlp` for subtitle extraction, `requests` for download, the `llm` Python library for LLM integration, and `rich` for formatted output with live Markdown rendering.

The legacy bash script is kept at `scripts/qv.sh` for reference.

## Dependencies

- `yt-dlp` - YouTube subtitle downloader (external CLI)
- `uv` - Python package manager and tool runner
- `llm` (Python library) - LLM integration (Simon Willison, llm.datasette.io)
- `typer`, `rich`, `requests` - installed automatically via `pyproject.toml`

## Installation & Testing

```bash
# Dev environment
make dev

# Install globally via uv tool
make install

# Check dependencies
make check_dependencies

# Uninstall
make uninstall

# Run directly from repo
.venv/bin/qv <URL> <question>
```

## Script Architecture

**Main entry point:** `src/vq/main.py`

Key functions:
- `check_dependencies()` - checks `yt-dlp` is available
- `normalize_url()` - handles shorts, youtu.be, standard URLs
- `get_video_id()` - extracts ID via yt-dlp subprocess
- `get_subtitle_url()` - fallback strategy: original lang → English → any auto
- `clean_subtitles()` - strips VTT formatting, HTML tags, timestamps
- `load_subtitles()` - cache layer (60-day TTL in `/tmp/qv_cache/`)
- `main()` - typer CLI entry point

**Key implementation details:**

1. **Argument parsing**: typer handles `url`, `question`, `-p/--language`, `-t/--template`, `--sub`, `--text-only`, `--debug`

2. **Subtitle download strategy**: original audio lang → English → any auto-generated VTT

3. **Caching**: `/tmp/qv_cache/{video_id}.txt` and `.title.txt`, auto-cleanup >60 days

4. **LLM integration**: uses `llm` Python library directly (no subprocess). Templates loaded via `llm.cli.load_template()`. Response streamed with live Markdown rendering via `rich.live.Live`.

5. **Output**: status messages via `rich.Console`, LLM response rendered as `rich.Markdown` in real time.

## Common Tasks

**Add new CLI option:** Edit `main()` function in `src/vq/main.py`

**Modify subtitle cleaning:** Edit `clean_subtitles()` in `src/vq/main.py`

**Change cache behavior:** Edit `load_subtitles()` in `src/vq/main.py`

**Adjust LLM prompt:** Edit system prompt construction in `main()` (search for `system_parts`)

## OpenSpec Workflow

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Development Notes

- The script uses bash functions for modularity (introduced in 2025-09-07 refactor)
- All error messages go to stdout (no stderr redirection)
- Return codes: 0 for success, 1 for errors
- Interactive prompts only appear for file overwrite confirmation (`-sub` option)
- Video title is cached separately to avoid repeated yt-dlp calls
