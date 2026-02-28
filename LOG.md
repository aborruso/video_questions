# LOG

## 2026-02-28

- **Renamed command `qv` → `vq`** (video questions, correct abbreviation)
- **Converted bash script to Python CLI**
  - New entry point: `src/vq/main.py` (typer + rich + llm Python library)
  - `requests` replaces `curl`; native `json` replaces `jq`
  - LLM integrated via Python library (no subprocess); templates via `llm.cli.load_template()`
  - LLM output rendered as streaming Markdown via `rich.live.Live`
  - Status messages with `rich.Status` and colored panels
  - `pyproject.toml` added; install via `uv tool install .`
  - Makefile updated: `make dev` (venv), `make install` (uv tool)
  - `scripts/qv.sh` kept as reference

## 2025-12-28

- **README and Makefile: install UX improvements**
  - Requirements moved before Installation (logical order)
  - LLM Configuration section added (API keys setup)
  - Dependency install instructions for Ubuntu/Debian/Fedora/Arch
  - Makefile: `test` target for post-install verification
  - Makefile: `help_install` target with distro-specific commands
  - Makefile: `check_dependencies` warns on missing llm keys (non-blocking)
  - Verify Installation section with troubleshooting
  - Option 2 renamed: "Run from Repository (No Install)"
  - Clarified automatic sudo in `make install`
  - Fixed `qv.sh.sha256` checksum
  - Fixed Anthropic setup: added `llm install llm-anthropic` step
  - Improved test command with more informative example
  - Added Cache Behavior section
  - Documented `make uninstall`

## 2025-12-22

- **Python migration plan** created in `docs/python-migration.md`
  - Complete migration strategy from bash to Python
  - 4-phase implementation plan (6 weeks estimated)
  - Cross-platform compatibility (Windows, macOS, Linux)
  - PyPI distribution with `pip install qv`
  - Backward compatibility strategy with 3-month parallel support
  - **Decision: Migration approved, starting in a few days**
- Created comprehensive development plan in `docs/future-ideas.md`
- Documented 5 development phases with priorities and effort estimates
- Sprint-based implementation roadmap (5 sprints)
- Enhanced CLAUDE.md with project architecture details
- Created `docs/NEXT.md` with first session tasks for Python migration

## 2025-09-07

- **Enhanced `qv.sh` script**:
  - Introduced `check_dependencies` function for robust dependency validation.
  - Refactored main logic into `qv` function for modularity.
  - Improved argument parsing with new options (`-p language`, `-t`, `-sub`, `--text-only`, `--debug`).
  - Added comprehensive YouTube URL validation and short URL conversion.
  - Implemented advanced subtitle download strategy (original language, English, auto-generated).
  - Enhanced cache management for subtitles and video titles.
  - Included subtitle content validation and optional saving to file.
  - Provided `--text-only` mode for subtitle output without LLM processing.
  - Refined LLM system prompt with video title and language support.
  - Integrated debug mode for LLM input inspection.

## 2025-08-14

- **Translated and renamed `idee.md` to `ideas.md`**: The file with enhancement ideas has been translated to English and renamed.
- **Fixed Makefile**: Improved the `Makefile` to correctly handle `sudo` and dependencies.
- **Added Makefile**: Created a `Makefile` to simplify installation, uninstallation, and dependency checking.
- **Updated documentation**: Updated `README.md` and `PRD.md` to reflect the new `Makefile`.
- **Improved argument handling**: The script now has more robust argument parsing and a more detailed help message.
- **Support for YouTube Shorts URLs**: Added support for `youtube.com/shorts/` URLs.
- **Improved cache management**: The cache now includes the video title, and files older than 60 days are deleted.
- **More robust subtitle download logic**: The script now searches for subtitles in the original language, then in English, and finally in any auto-generated language.
- **Added debug mode**: A new `--debug` option allows you to view the input sent to the LLM.
- **Code refactoring**: The code has been reorganized into functions (`qv` and `main`) for better readability and maintainability.

## 2025-07-26

- **Added Product Requirements Document**: Created the `PRD.md` file to outline the project's goals and features.

## 2025-07-04

- **Added enhancement ideas**: Created the `idee.md` file to collect ideas for future features.

## 2025-07-02

- Added support for YouTube Shorts URLs.

## 2025-06-30

- Enabled automatic cleanup of cache files older than 60 days.

## 2025-06-18

- Added caching system for subtitles to improve performance and reduce API calls.

## 2025-06-10

- First public release of the project.
