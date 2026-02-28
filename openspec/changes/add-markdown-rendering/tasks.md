## 1. Implementation

- [x] 1.1 Add `rich` dependency to `pyproject.toml`
- [x] 1.2 Import `rich.live.Live` and `rich.markdown.Markdown` in `src/qv/main.py`
- [x] 1.3 Wrap LLM streaming response in `Live(Markdown(...))` context manager
- [x] 1.4 Accumulate streamed chunks and update live Markdown display on each chunk

## 2. Validation

- [ ] 2.1 Run `qv <url> <question>` and confirm response renders as formatted Markdown
- [ ] 2.2 Verify headers, bold, lists, and code blocks are styled correctly
- [ ] 2.3 Verify streaming is live (text appears progressively, not all at once)
