# LOG

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
