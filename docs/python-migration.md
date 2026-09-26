# Python Migration Plan

## Rationale

Migrating from bash to Python would provide:

**Distribution & Installation:**
- PyPI package: `pip install qv` (vs manual install/PATH setup)
- Automatic dependency management via pip
- Version pinning and updates: `pip install --upgrade qv`
- Works on Windows without WSL/Cygwin

**Developer Experience:**
- Easier to test (pytest vs bats)
- Better error handling and type hints
- Richer ecosystem for future features
- More contributors (Python > bash developers)

**User Experience:**
- Cross-platform compatibility
- Better progress indicators and async operations
- Potential for plugin system
- Native config file parsing (YAML/TOML)

## Current Architecture (Bash)

```
qv.sh (344 lines)
├── check_dependencies()
├── qv()
│   ├── Argument parsing
│   ├── URL validation
│   ├── Cache management
│   ├── Subtitle download (yt-dlp)
│   ├── Subtitle processing
│   └── LLM interaction
└── main()
```

**External dependencies:**
- yt-dlp (subprocess)
- curl (subprocess)
- llm (subprocess)
- jq (subprocess)

## Proposed Python Architecture

```
qv/
├── __init__.py
├── __main__.py          # Entry point (python -m qv)
├── cli.py               # Click-based CLI
├── core.py              # Main logic
│   ├── class VideoProcessor
│   │   ├── validate_url()
│   │   ├── download_subtitles()
│   │   ├── process_subtitles()
│   │   └── query_llm()
│   └── class CacheManager
├── config.py            # Config file handling
├── models.py            # Data classes (Video, Subtitle, etc.)
├── exceptions.py        # Custom exceptions
└── utils.py             # Helpers

tests/
├── test_cli.py
├── test_core.py
├── test_cache.py
└── fixtures/
    └── sample_subtitle.vtt
```

## Library Choices

### CLI Framework
**Choice:** Click
- De facto standard for Python CLIs
- Great help formatting
- Parameter validation built-in
- Easy subcommands for future features

**Alternative:** argparse (stdlib, but more verbose)

### YouTube Integration
**Choice:** yt-dlp (keep as subprocess)
- Already used and reliable
- Python bindings exist but subprocess is simpler
- Maintains current behavior

**Alternative:** yt-dlp Python API (more complex, not needed)

### LLM Integration
**Phase 1:** Keep llm CLI (subprocess)
- Minimal change, maintains compatibility
- Users already configured llm

**Phase 2 (future):** Native Python LLM libraries
- anthropic, openai SDKs directly
- More control, better error handling
- Allows streaming responses

### HTTP Requests
**Choice:** httpx
- Modern, async-capable
- Better than requests for new projects
- Needed for subtitle downloads

**Alternative:** requests (older but stable)

### Config File
**Choice:** TOML via tomllib (Python 3.11+) or tomli
- Modern, readable format
- Standard for Python projects (pyproject.toml)

**Format:**
```toml
[qv]
cache_dir = "~/.cache/qv"
cache_days = 60
default_language = "Italian"

[llm]
default_template = "andy"
model = "claude-sonnet-4"
```

### Caching
**Choice:** Custom file-based (keep current approach)
- Simple, no external dependencies
- Works cross-platform
- Easy migration from bash version

**Alternative:** SQLite (overkill for this use case)

## Migration Phases

### Phase 1: Core Parity (Week 1-2)

**Goal:** Feature parity with bash version

**Tasks:**
- [ ] Set up project structure (pyproject.toml, src layout)
- [ ] Implement CLI with Click (all current flags)
- [ ] Port URL validation logic
- [ ] Port cache management
- [ ] Port subtitle download (yt-dlp subprocess)
- [ ] Port subtitle processing
- [ ] Port LLM interaction (llm subprocess)
- [ ] Add basic tests (pytest)
- [ ] Documentation (README update)

**Deliverable:** `qv` works identically to bash version

### Phase 2: Python Improvements (Week 3)

**Goal:** Leverage Python ecosystem

**Tasks:**
- [ ] Add config file support (TOML)
- [ ] Better error messages (custom exceptions)
- [ ] Type hints throughout
- [ ] Async subtitle downloads (for future playlist support)
- [ ] Progress bars (rich or tqdm)
- [ ] Logging instead of echo (configurable verbosity)

**Deliverable:** Better UX than bash version

### Phase 3: Distribution (Week 4)

**Goal:** Easy installation

**Tasks:**
- [ ] Package for PyPI
- [ ] GitHub Actions for CI/CD
- [ ] Automated releases
- [ ] Docker image (optional)
- [ ] Homebrew formula (optional)

**Deliverable:** `pip install qv` works

### Phase 4: Advanced Features (Week 5+)

**Goal:** Features hard to do in bash

**Tasks:**
- [ ] Interactive mode with prompt_toolkit
- [ ] Playlist support with concurrent processing
- [ ] Plugin system for custom LLM providers
- [ ] Export to multiple formats (JSON, Markdown)
- [ ] Subtitle translation with deep-translator

**Deliverable:** Feature-rich beyond bash limitations

## Backward Compatibility

### Transition Strategy

**Option 1: Hard cutover**
- Replace bash script with Python
- Update installation instructions
- Archive bash version in `legacy/` branch

**Pros:** Clean break, focus on Python
**Cons:** May break existing workflows

**Option 2: Parallel installation**
- Keep bash as `qv` or `qv.sh`
- Python as `qv-py` initially, then `qv` after deprecation period
- Both maintained for 3-6 months

**Pros:** Smooth transition for users
**Cons:** Maintenance burden

**Recommendation:** Option 2 with clear migration timeline

### Compatibility Matrix

| Feature | Bash | Python v1 | Python v2 |
|---------|------|-----------|-----------|
| Basic query | ✓ | ✓ | ✓ |
| Cache | ✓ | ✓ | ✓ (improved) |
| Templates | ✓ | ✓ | ✓ |
| Language | ✓ | ✓ | ✓ |
| Text-only | ✓ | ✓ | ✓ |
| Config file | ✗ | ✓ | ✓ |
| Interactive | ✗ | ✗ | ✓ |
| Playlist | ✗ | ✗ | ✓ |
| Windows | ✗ | ✓ | ✓ |

## Dependencies

### Runtime Dependencies (pyproject.toml)

```toml
[project]
name = "qv"
version = "2.0.0"
requires-python = ">=3.9"

dependencies = [
    "click>=8.0",
    "httpx>=0.24",
    "tomli>=2.0; python_version<'3.11'",
    "rich>=13.0",  # for progress bars
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "black>=23.0",
    "ruff>=0.1.0",
    "mypy>=1.0",
]
```

### External Tools (still required)
- yt-dlp (install separately or via pip: `yt-dlp`)
- llm (install separately: `pip install llm`)

**Future:** Bundle yt-dlp as dependency, integrate LLM SDKs

## Project Structure (Full)

```
video_questions/
├── pyproject.toml
├── README.md
├── LICENSE
├── CHANGELOG.md
├── src/
│   └── qv/
│       ├── __init__.py
│       ├── __main__.py
│       ├── cli.py
│       ├── core.py
│       ├── cache.py
│       ├── config.py
│       ├── models.py
│       ├── exceptions.py
│       ├── utils.py
│       └── constants.py
├── tests/
│   ├── __init__.py
│   ├── test_cli.py
│   ├── test_core.py
│   ├── test_cache.py
│   ├── test_config.py
│   └── fixtures/
├── docs/
│   ├── installation.md
│   ├── configuration.md
│   ├── api.md
│   └── contributing.md
├── scripts/
│   └── qv.sh  # Legacy bash version
└── .github/
    └── workflows/
        ├── test.yml
        └── publish.yml
```

## Code Examples

### CLI Entry Point (cli.py)

```python
import click
from qv.core import VideoProcessor
from qv.config import load_config

@click.command()
@click.argument('url')
@click.argument('question', required=False)
@click.option('-sub', '--subtitle-file', help='Save subtitles to file')
@click.option('-t', '--template', help='LLM template')
@click.option('-p', '--param', multiple=True, help='LLM parameters')
@click.option('--text-only', is_flag=True, help='Output subtitles only')
@click.option('--summarize', is_flag=True, help='Summarize video')
@click.option('--debug', is_flag=True, help='Debug mode')
@click.version_option()
def main(url, question, subtitle_file, template, param, text_only, summarize, debug):
    """Query YouTube videos using natural language."""

    config = load_config()
    processor = VideoProcessor(config)

    try:
        result = processor.process(
            url=url,
            question=question or ("Summarize this video" if summarize else None),
            subtitle_file=subtitle_file,
            template=template,
            text_only=text_only,
            debug=debug
        )
        click.echo(result)
    except Exception as e:
        click.secho(f"Error: {e}", fg='red', err=True)
        raise SystemExit(1)

if __name__ == '__main__':
    main()
```

### Core Logic (core.py)

```python
from dataclasses import dataclass
from pathlib import Path
import subprocess
import httpx
from qv.cache import CacheManager
from qv.models import Video, Subtitle

class VideoProcessor:
    def __init__(self, config):
        self.config = config
        self.cache = CacheManager(config.cache_dir)

    def process(self, url: str, question: str | None, **kwargs) -> str:
        video = self.validate_url(url)
        subtitle = self.get_subtitle(video)

        if kwargs.get('text_only'):
            return subtitle.text

        if kwargs.get('subtitle_file'):
            Path(kwargs['subtitle_file']).write_text(subtitle.text)

        return self.query_llm(subtitle, question, **kwargs)

    def validate_url(self, url: str) -> Video:
        # Port bash URL validation logic
        ...

    def get_subtitle(self, video: Video) -> Subtitle:
        # Check cache first
        if cached := self.cache.get(video.id):
            return cached

        # Download via yt-dlp
        subtitle = self.download_subtitle(video)
        self.cache.set(video.id, subtitle)
        return subtitle

    def download_subtitle(self, video: Video) -> Subtitle:
        # Port yt-dlp logic
        result = subprocess.run([
            'yt-dlp', '--skip-download',
            '--write-auto-sub', '--print', 'requested_subtitles.en.url',
            video.url
        ], capture_output=True, text=True)

        subtitle_url = result.stdout.strip()
        response = httpx.get(subtitle_url)

        return Subtitle(
            text=self.clean_subtitle(response.text),
            language='en'
        )

    def clean_subtitle(self, raw: str) -> str:
        # Port sed/grep processing logic
        ...

    def query_llm(self, subtitle: Subtitle, question: str, **kwargs) -> str:
        # Port llm subprocess logic
        ...
```

### Models (models.py)

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass
class Video:
    id: str
    url: str
    title: str | None = None

@dataclass
class Subtitle:
    text: str
    language: str
    timestamps: list[tuple[str, str]] | None = None  # For future timestamp feature

@dataclass
class CacheEntry:
    video_id: str
    subtitle: Subtitle
    cached_at: datetime

    def is_expired(self, max_age_days: int) -> bool:
        age = (datetime.now() - self.cached_at).days
        return age > max_age_days
```

## Testing Strategy

### Unit Tests (pytest)

```python
# tests/test_core.py
import pytest
from qv.core import VideoProcessor
from qv.exceptions import InvalidURLError

def test_url_validation():
    processor = VideoProcessor(config={})

    # Valid URLs
    assert processor.validate_url('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
    assert processor.validate_url('https://youtu.be/dQw4w9WgXcQ')
    assert processor.validate_url('https://youtube.com/shorts/dQw4w9WgXcQ')

    # Invalid URLs
    with pytest.raises(InvalidURLError):
        processor.validate_url('https://example.com')

def test_subtitle_cleaning():
    processor = VideoProcessor(config={})
    raw = """
    1
    00:00:01,000 --> 00:00:05,000
    Hello <b>world</b>

    2
    00:00:05,000 --> 00:00:10,000
    This is a test
    """

    cleaned = processor.clean_subtitle(raw)
    assert cleaned == "Hello world This is a test"
    assert "<b>" not in cleaned
```

### Integration Tests

```python
# tests/test_integration.py
from click.testing import CliRunner
from qv.cli import main

def test_cli_text_only(mocker):
    runner = CliRunner()

    # Mock yt-dlp subprocess
    mocker.patch('subprocess.run', return_value=...)

    result = runner.invoke(main, [
        'https://youtu.be/TEST',
        '--text-only'
    ])

    assert result.exit_code == 0
    assert 'subtitles' in result.output
```

## Migration Checklist

### Pre-Migration
- [ ] Announce Python migration plan in README
- [ ] Create feature branch `python-port`
- [ ] Set up Python project structure
- [ ] Choose libraries and create pyproject.toml

### Development
- [ ] Port core functionality (Week 1-2)
- [ ] Add tests with >80% coverage
- [ ] Benchmark performance vs bash (should be similar)
- [ ] Alpha testing with 3-5 users

### Distribution
- [ ] Create PyPI account/token
- [ ] Set up GitHub Actions for releases
- [ ] Test `pip install` on clean environments (Linux, macOS, Windows)
- [ ] Write migration guide for bash users

### Launch
- [ ] Release v2.0.0 on PyPI
- [ ] Update README with Python installation as primary
- [ ] Mark bash version as legacy (but still available)
- [ ] Announce on social media / relevant forums

### Post-Launch
- [ ] Monitor issues for migration problems
- [ ] Maintain bash version for 3 months (critical bugs only)
- [ ] After 3 months: deprecate bash, Python only

## Timeline

**Conservative estimate:** 4-6 weeks full-time
**Realistic (part-time):** 2-3 months

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1-2 | Core porting | Working Python CLI |
| 3 | Polish & testing | Test coverage >80% |
| 4 | Distribution setup | PyPI package |
| 5+ | Advanced features | Beyond bash parity |

## Risks & Mitigations

**Risk:** Users can't install Python/pip
**Mitigation:** Provide standalone executables (PyInstaller) for major platforms

**Risk:** Performance regression
**Mitigation:** Benchmark early, optimize if needed (likely not required)

**Risk:** Breaking changes upset users
**Mitigation:** Clear communication, parallel support period, migration guide

**Risk:** Scope creep during port
**Mitigation:** Strict feature parity in Phase 1, improvements in Phase 2+

## Success Metrics

- PyPI downloads >100/month within 3 months
- GitHub issues for migration problems <10%
- All bash features working in Python
- Test coverage >80%
- Windows/macOS/Linux all supported
- Installation time: <1 minute (`pip install qv`)

## Open Questions

1. **Should Phase 1 include config file support?**
   - Pro: Easy to add while porting
   - Con: Scope creep, not in bash version

2. **Bundle yt-dlp or keep as external dependency?**
   - Pro: Simpler for users
   - Con: Larger package size, update responsibility

3. **Keep llm CLI or switch to native SDKs?**
   - Pro (CLI): Maintains compatibility
   - Pro (SDK): More control, better errors
   - Decision: CLI for v2.0, SDK for v2.1+

4. **Support Python 3.9+ or 3.11+?**
   - 3.9+: Wider compatibility (Ubuntu 20.04)
   - 3.11+: Better performance, native tomllib
   - Decision: 3.9+ for adoption, use tomli backport
