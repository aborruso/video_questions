# Todo: CLI improvements

## Phase 1 – Quick fixes
- [x] Spostare `import time` in cima al file (riga 130 → top)

## Phase 2 – Nuove opzioni CLI
- [x] Aggiungere `--no-cache` per saltare la cache (download forzato)
- [x] Aggiungere `-m/--model` per passare il modello a `llm`
- [x] Aggiungere `-o/--output` per salvare la risposta LLM su file

## Review
- `import time` spostato tra gli import standard in cima
- `--no-cache`: aggiunto parametro a `load_subtitles()`, salta il branch cache
- `-m/--model`: inserisce `-m <model>` subito dopo `llm` nel comando
- `-o/--output`: scrive `full_text` su file dopo lo streaming, con conferma green

