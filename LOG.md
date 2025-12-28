# LOG

## 2025-12-28

- **README e Makefile: miglioramenti UX installazione**
  - Requirements spostato PRIMA di Installation (ordine logico)
  - Sezione LLM Configuration aggiunta (setup API keys CRITICO)
  - Istruzioni install deps per Ubuntu/Debian/Fedora/Arch
  - Makefile: target `test` per verifica post-install
  - Makefile: target `help_install` con comandi distro-specific
  - Makefile: `check_dependencies` con warning llm keys (non blocca)
  - Sezione Verify Installation con troubleshooting
  - Option 2 rinominata: "Run from Repository (No Install)"
  - Chiarito uso sudo automatico in `make install`
  - Fix checksum file `qv.sh.sha256` (hash aggiornato)

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
