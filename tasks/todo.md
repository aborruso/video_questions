# Task: modalità chat interattiva (-i/--chat)

## Obiettivo
Dopo la prima risposta LLM, restare in una sessione REPL inline dove l'utente
continua a fare domande sullo stesso transcript, sfruttando la continuazione
conversazione di `llm`.

## Decisioni (confermate con l'utente)
- Attivazione: flag opt-in `-i/--chat` (default invariato, stdout pipe-safe).
- Interfaccia: REPL inline con rich (mantiene il rendering live Markdown attuale).
- Continuazione: `llm -c` (continua la conversazione più recente). In un REPL
  ogni turno è l'ultimo, quindi resta agganciato alla stessa conversazione.
  Niente parsing di `llm logs --json` né cattura del cid.

## Fasi
1. Estrarre lo streaming LLM in helper riusabile `stream_llm(cmd, prompt_text, video_id)`.
2. Aggiungere flag `-i/--chat` a `main()`.
3. Primo turno = flusso attuale (usa `stream_llm`).
4. Se `chat`: loop REPL.
   - Prompt utente su stderr; invio vuoto / `exit`/`quit` / EOF / Ctrl-C → esci.
   - Ogni follow-up: `llm -c` con la domanda su stdin, stream + linkify.
   - Se è stato usato `-m/--model`, ripassarlo su `-c` (llm lo richiede per coerenza modello).
5. Guardie: `-i` richiede una `question`; ignorato in `--text-only`/`--metadata`.
6. Aggiornare help/docstring ed esempi.

## Review
- Estratto lo streaming LLM in `stream_llm(cmd, prompt_text, video_id)`; usato sia
  dal primo turno che dai follow-up. Nessuna duplicazione.
- `chat_loop(video_id)`: REPL con `Prompt.ask` su stderr; follow-up = `llm -c` con
  domanda su stdin. Uscita su vuoto/exit/quit/EOF/Ctrl-C.
- Follow-up NON ripassa `-m/-s`: `llm -c` riusa modello e system prompt della
  conversazione (verificato: contesto mantenuto nel test end-to-end).
- Flag `-i/--chat` opt-in; guardia: richiede una `question`. Default e stdout
  pipe-safe invariati (regressione verificata: modalità normale → solo stdout, exit 0).
- Doc aggiornate: docstring/help con nuova modalità ed esempi, LOG.md, CLAUDE.md.
