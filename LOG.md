# LOG

## 2025-08-14

- **Migliorata la gestione degli argomenti**: Lo script ora ha un parsing degli argomenti più robusto e un messaggio di aiuto più dettagliato.
- **Supporto per URL di YouTube Shorts**: Aggiunto il supporto per gli URL di tipo `youtube.com/shorts/`.
- **Migliorata la gestione della cache**: La cache ora include il titolo del video e i file più vecchi di 60 giorni vengono eliminati.
- **Logica di download dei sottotitoli più robusta**: Lo script ora cerca i sottotitoli nella lingua originale, poi in inglese e infine in qualsiasi lingua auto-generata.
- **Aggiunta la modalità di debug**: Una nuova opzione `--debug` permette di visualizzare l'input inviato all'LLM.
- **Refactoring del codice**: Il codice è stato riorganizzato in funzioni (`qv` e `main`) per una migliore leggibilità e manutenibilità.

## 2025-07-26

- **Aggiunta la documentazione dei requisiti di prodotto**: Creato il file `PRD.md` per delineare gli obiettivi e le funzionalità del progetto.

## 2025-07-04

- **Aggiunte idee di potenziamento**: Creato il file `idee.md` per raccogliere idee su future funzionalità.

## 2025-07-02

- Added support for YouTube Shorts URLs.

## 2025-06-30

- Enabled automatic cleanup of cache files older than 60 days.

## 2025-06-18

- Added caching system for subtitles to improve performance and reduce API calls.

## 2025-06-10

- First public release of the project.