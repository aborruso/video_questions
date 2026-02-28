# Change: Enable Markdown rendering for LLM output

## Why
The LLM often returns structured Markdown (headers, lists, code blocks). Without rendering, the output appears as raw text with syntax noise (`**bold**`, `# heading`), reducing readability.

## What Changes
- LLM response is rendered as formatted Markdown in the terminal instead of raw text
- Output streams in real time (live rendering as tokens arrive)

## Impact
- Affected specs: `llm-output`
- Affected code: `src/qv/main.py` (LLM response handling)
