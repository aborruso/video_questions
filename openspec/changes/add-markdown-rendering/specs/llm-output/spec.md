## ADDED Requirements

### Requirement: Markdown Rendering of LLM Response
The CLI SHALL render the LLM response as formatted Markdown in the terminal, streaming output in real time as tokens arrive.

#### Scenario: Markdown headers and lists are rendered
- **WHEN** the LLM returns a response containing Markdown syntax (e.g., `## Title`, `- item`)
- **THEN** the terminal displays formatted output (styled headers, bullet lists) instead of raw Markdown characters

#### Scenario: Response streams progressively
- **WHEN** the LLM starts generating tokens
- **THEN** the terminal updates the rendered output in real time, chunk by chunk, without waiting for the full response

#### Scenario: Plain text response is displayed unchanged
- **WHEN** the LLM returns a response with no Markdown syntax
- **THEN** the terminal displays the plain text correctly without artifacts or extra formatting
