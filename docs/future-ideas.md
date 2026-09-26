# Development Plan and Enhancement Ideas

> **NOTE:** Before implementing these features, consider the [Python migration plan](python-migration.md) which provides a more solid foundation for long-term development. Python migration enables easier testing, cross-platform support, and broader distribution via PyPI.

## Quick Wins (Phase 1)

### 1.1 Add --summarize flag
**Priority:** High
**Effort:** 1 hour
**Impact:** High user value with minimal code

**Implementation:**
- Add `--summarize` option to argument parser (scripts/qv.sh:26-79)
- Set predefined question: "Provide a concise summary of the main points covered in this video"
- Update help text with example usage

**Benefits:**
- Most common use case (users don't always have specific questions)
- No LLM prompt engineering needed
- Can be combined with `-p language` for localized summaries

### 1.2 Configuration file support
**Priority:** Medium
**Effort:** 2 hours
**Impact:** Better UX for power users

**Implementation:**
- Read `~/.config/qv/config` if exists
- Support variables:
  - `DEFAULT_TEMPLATE` - default llm template
  - `CACHE_DIR` - custom cache location
  - `DEFAULT_LANG` - preferred response language
  - `CACHE_DAYS` - cache expiration (default 60)
- Config values overridden by CLI flags

**Example config:**
```bash
DEFAULT_TEMPLATE=andy
CACHE_DIR=~/Documents/qv_cache
DEFAULT_LANG=Italian
CACHE_DAYS=30
```

### 1.3 Improved error messages
**Priority:** Medium
**Effort:** 2 hours
**Impact:** Better debugging experience

**Implementation:**
- Capture yt-dlp exit codes and provide specific errors:
  - Exit 1: Generic error
  - Contains "403": Video protected/geoblocked
  - Contains "Private": Video is private
  - Contains "removed": Video deleted
- Add `--verbose` flag to show full yt-dlp output
- Better distinction between network errors vs content unavailability

## Testing Infrastructure (Phase 2)

### 2.1 Automated testing with bats
**Priority:** High
**Effort:** 4 hours
**Impact:** Code quality and regression prevention

**Implementation:**
- Install bats-core as dev dependency
- Create `tests/test_qv.sh` with test cases:
  - URL validation (valid/invalid formats)
  - Argument parsing (all flag combinations)
  - Cache behavior (hit/miss/expiration)
  - Subtitle processing (mocked yt-dlp output)
- Add `make test` target to Makefile
- Mock external dependencies (yt-dlp, curl, llm)

**Test structure:**
```bash
tests/
├── test_url_validation.bats
├── test_cache.bats
├── test_subtitle_processing.bats
└── fixtures/
    └── sample_subtitle.vtt
```

### 2.2 Shellcheck compliance
**Priority:** Medium
**Effort:** 2 hours
**Impact:** Code quality

**Implementation:**
- Run `shellcheck scripts/qv.sh`
- Fix all warnings and errors
- Add shellcheck to CI (if using GitHub Actions)
- Document any intentional suppressions with inline comments

## Killer Features (Phase 3)

### 3.1 Timestamp retention and citation
**Priority:** High
**Effort:** 6-8 hours
**Impact:** Game-changer feature

**Current issue:** Timestamps are stripped during subtitle processing (line 220-226)

**Implementation:**
- Modify subtitle processing pipeline to preserve timestamps
- Store parallel arrays: `content[]` and `timestamps[]`
- Format for LLM: Include timestamp markers in text
  ```
  [00:32] Introduction to the topic
  [02:15] First main point
  ```
- Update system prompt to instruct LLM to cite timestamps
- Optional flag `--no-timestamps` to disable

**Example output:**
```
Q: What is discussed about dependency management?
A: The video covers dependency management at [05:32], explaining
   that npm workspaces solve monorepo challenges. At [08:45],
   the author demonstrates a practical example.
```

### 3.2 Interactive mode
**Priority:** Medium
**Effort:** 4 hours
**Impact:** Better UX for deep video exploration

**Implementation:**
- Add `--interactive` flag
- After initial subtitle download, enter REPL loop
- Prompt: `qv> ` for subsequent questions
- Commands:
  - Regular text → send as question to LLM
  - `/save <file>` → save transcript
  - `/title` → show video title
  - `/quit` or Ctrl+D → exit
- Reuse cached content and system prompt

**Example session:**
```bash
$ qv https://youtu.be/VIDEO_ID --interactive
Using cached subtitles...
Video: "Introduction to Rust"

qv> What is ownership?
[LLM response...]

qv> What about borrowing?
[LLM response...]

qv> /quit
```

### 3.3 Playlist support
**Priority:** Low
**Effort:** 6 hours
**Impact:** Niche but powerful for tutorial series

**Implementation:**
- Add `--playlist <url>` option
- Use yt-dlp to extract video IDs from playlist
- For each video:
  - Download subtitles (with caching)
  - Ask the same question
  - Aggregate results
- Output format options:
  - `--playlist-format summary` → one combined answer
  - `--playlist-format individual` → per-video answers
  - `--playlist-format json` → structured data

**Example:**
```bash
qv --playlist <playlist-url> "What tools are mentioned?" \
   --playlist-format summary
```

## Technical Improvements (Phase 4)

### 4.1 Multiple subtitle format support
**Priority:** Low
**Effort:** 3 hours
**Impact:** Better compatibility

**Implementation:**
- Current: VTT only
- Add fallback chain: VTT → SRT → JSON3 → TXT
- Unified processing for all formats
- Each format has specific cleaning logic

### 4.2 Progress indicators
**Priority:** Low
**Effort:** 1 hour
**Impact:** Better UX for slow connections

**Implementation:**
- Add progress messages to stderr (not stdout)
- Show status for:
  - Subtitle download
  - LLM processing
  - Cache operations
- Use simple text (no fancy spinners for simplicity)

**Example:**
```bash
[qv] Detecting video language...
[qv] Downloading subtitles...
[qv] Processing with LLM...
```

### 4.3 Subtitle quality detection
**Priority:** Low
**Effort:** 2 hours
**Impact:** Better user awareness

**Implementation:**
- Detect subtitle type: manual vs auto-generated
- Warn user if using auto-generated (lower quality)
- Show language detected: "Using auto-generated subtitles (Italian)"

## Documentation Enhancements (Phase 5)

### 5.1 Troubleshooting guide
**Priority:** High
**Effort:** 2 hours
**Impact:** Reduced support burden

**Add to README:**
- Common errors with solutions
- yt-dlp configuration issues
- llm setup guide
- Cache corruption recovery
- Firewall/proxy issues with YouTube

### 5.2 Real-world examples
**Priority:** Medium
**Effort:** 1 hour
**Impact:** Better onboarding

**Add to README:**
- Show actual command + output for common scenarios
- Include different video types (tutorial, interview, lecture)
- Demonstrate all major flags in context

### 5.3 Video demo
**Priority:** Low
**Effort:** 3 hours
**Impact:** Marketing/onboarding

- Record 2-minute screencast showing:
  - Basic usage
  - Cache behavior
  - Template switching
  - Interactive mode (when implemented)
- Host on YouTube (meta!)
- Link from README

## From ideas.md (already documented)

These ideas are already captured in `ideas.md` and can be considered for future phases:

- Article/post creation from videos
- Social media post generation
- Local file support (with whisper.cpp)
- Web page analysis (non-YouTube URLs)
- Subtitle translation
- Multiple output formats (JSON, Markdown)

## Recommended Implementation Order

### Sprint 1 (Week 1)
1. Add --summarize flag (1.1)
2. Improved error messages (1.3)
3. Troubleshooting guide (5.1)

**Outcome:** Better UX with minimal effort

### Sprint 2 (Week 2-3)
1. Automated testing (2.1)
2. Shellcheck compliance (2.2)
3. Configuration file support (1.2)

**Outcome:** Solid foundation for future development

### Sprint 3 (Week 4-5)
1. Timestamp retention (3.1)

**Outcome:** Killer feature that differentiates from alternatives

### Sprint 4 (Week 6)
1. Interactive mode (3.2)
2. Progress indicators (4.2)

**Outcome:** Polished user experience

### Sprint 5+ (Future)
- Playlist support (3.3)
- Additional features from ideas.md as needed

## Success Metrics

- **Code quality:** All tests passing, shellcheck clean
- **User satisfaction:** GitHub stars, user feedback
- **Performance:** Cache hit rate >70% for repeated queries
- **Reliability:** <5% failure rate on publicly accessible videos
