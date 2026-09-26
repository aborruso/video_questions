# Next Steps: Python Migration

## Decision

**Migration to Python chosen** (Option A from python-migration.md)

Starting in a few days with Phase 1: Core Parity (Week 1-2)

## Pre-Work Checklist (before starting)

- [ ] Review `docs/python-migration.md`
- [ ] Decide on Python version requirement (recommend 3.9+)
- [ ] Choose project name for PyPI (is `qv` available?)
- [ ] Create feature branch: `git checkout -b python-port`
- [ ] Set up basic pyproject.toml

## First Session Tasks

**Goal:** Working Python CLI with URL validation

1. Create project structure:
   ```bash
   mkdir -p src/qv tests
   touch src/qv/{__init__.py,__main__.py,cli.py,core.py}
   ```

2. Set up pyproject.toml with Click dependency

3. Port URL validation from bash (scripts/qv.sh:101-122)

4. Create basic Click CLI accepting URL + question

5. Add first test for URL validation

**Time estimate:** 2-3 hours

## References

- Full migration plan: `docs/python-migration.md`
- Current bash implementation: `scripts/qv.sh`
- Architecture details: `CLAUDE.md`

## Notes

- Keep bash version working during migration
- Test on Linux first, then macOS, then Windows
- Maintain same CLI interface for easy user migration
