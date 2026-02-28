# Plan: Convert qv from bash to Python CLI

## Phase 1: Python project setup

- [x] Create `pyproject.toml` with dependencies: typer, rich, requests, llm
- [x] Initialize uv venv with `uv venv`
- [x] Install dependencies with `uv pip install -e .`
- [x] Create `src/vq/` package structure

## Phase 2: Python CLI implementation

- [x] Write `src/vq/main.py` with:
  - typer for argument parsing (same interface as bash: url, question, -p language, -t template, --sub, --text-only, --debug)
  - `requests` replaces `curl`
  - native `json` replaces `jq`
  - `yt-dlp` and `llm` kept as external dependencies
  - Status output via `rich.console.Console`
  - LLM response rendered as `rich.Markdown` with live streaming
  - Same caching, subtitle download, and cleaning logic

## Phase 3: Infrastructure update

- [x] Update Makefile: `make dev` (uv venv), `make install` (uv tool)
- [x] Update CLAUDE.md with new architecture
- [x] Update LOG.md

## Open questions (resolved)

- Keep `scripts/qv.sh`? → Yes, kept as reference
- Entry point name? → `qv`
- LLM template support? → Via `llm.cli.load_template()` Python API

---

## Review

### Changes made

- `pyproject.toml` added with typer, rich, requests, llm dependencies
- `src/vq/main.py`: full Python CLI replacing `scripts/qv.sh`
  - `requests` replaces `curl`; `json` replaces `jq`
  - `llm` used as Python library with streaming support
  - Templates loaded via `llm.cli.load_template()`
  - LLM response streamed live as rendered Markdown (`rich.live.Live`)
  - Status messages and panels via `rich`
- Makefile: `make dev` sets up uv venv, `make install` uses `uv tool install .`
- CLAUDE.md updated with new architecture docs
- `scripts/qv.sh` kept as reference
