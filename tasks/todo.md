# Plan: Migliorare README e controlli installazione

## Fase 1: Ristrutturazione README

### Task 1.1: Riorganizzare sezioni
- [ ] Spostare Requirements prima di Installation
- [ ] Nuova struttura:
  1. Project Overview
  2. Requirements
  3. LLM Configuration (NUOVO)
  4. Installation
  5. Verify Installation (NUOVO)
  6. Usage
  7. Options
  8. Examples

### Task 1.2: Aggiungere sezione Requirements dettagliata
- [ ] Aggiungere comandi installazione per Ubuntu/Debian
- [ ] Aggiungere comandi installazione per Fedora/RHEL
- [ ] Aggiungere comandi installazione per Arch
- [ ] Includere note su Python 3 e pip3

### Task 1.3: Aggiungere sezione LLM Configuration (CRITICO)
- [ ] Spiegare necessità configurazione API key
- [ ] Esempi setup OpenAI
- [ ] Esempi setup Anthropic
- [ ] Comando verifica setup funzionante
- [ ] Link a documentazione llm per altri provider

### Task 1.4: Migliorare sezione Installation
- [ ] Rinominare Option 2: "Run from repository (no install)"
- [ ] Chiarire che `make install` gestisce sudo automaticamente
- [ ] Aggiungere riferimento a `make help_install` per help dipendenze

### Task 1.5: Aggiungere sezione Verify Installation
- [ ] Comando `make test` per test post-install
- [ ] Esempio test manuale con --text-only
- [ ] Troubleshooting comune (missing deps, llm not configured)

## Fase 2: Miglioramenti Makefile

### Task 2.1: Aggiungere target test
- [ ] Creare target `test` che scarica e mostra prime 5 righe subtitles
- [ ] Test deve verificare che tutte dipendenze funzionano end-to-end
- [ ] Output chiaro se test passa o fallisce

### Task 2.2: Aggiungere target help_install
- [ ] Comandi per Ubuntu/Debian
- [ ] Comandi per Fedora/RHEL
- [ ] Comandi per Arch Linux
- [ ] Note su LLM configuration necessaria

### Task 2.3: Migliorare check_dependencies
- [ ] Aggiungere check se llm ha almeno un model configurato
- [ ] Warning se llm non ha API keys (non bloccare, solo avvisare)
- [ ] Output più informativo sui missing deps

## Fase 3: Fix tecnici

### Task 3.1: Verificare checksum file
- [ ] Verificare che qv.sh.sha256 corrisponda a scripts/qv.sh
- [ ] Se path è sbagliato, aggiornare sha256 o documentazione
- [ ] Testare procedura download standalone + verifica

### Task 3.2: Migliorare chiarezza sudo
- [ ] Nel README spiegare quando serve sudo
- [ ] Verificare Makefile gestisce permessi correttamente
- [ ] Test su sistema senza permessi /usr/local/bin

## Domande aperte - RISOLTE

1. **Video test per make test**: ✅ OK usa https://www.youtube.com/watch?v=OM6XIICm_qo
2. **llm check**: in `check_dependencies`, verificare se llm ha API keys configurate? (potrebbe richiedere chiamata API = costi)
3. **Checksum**: ✅ mantenere e correggere path inconsistency
4. **Distro coverage**: ✅ solo Linux

## Note implementazione

- Ogni modifica deve essere minima e focalizzata
- Non cambiare funzionalità esistenti
- Solo miglioramenti documentazione e DX
- Testare ogni change con install pulito

---

## Review: Modifiche Completate

### Modifiche Makefile

**1. Target `test` aggiunto**
- Verifica installazione con test su video reale
- Mostra prime 5 righe subtitles
- Comandi: `make test`

**2. Target `help_install` aggiunto**
- Comandi installazione dipendenze per Ubuntu/Debian, Fedora/RHEL, Arch
- Include setup llm keys
- Comandi: `make help_install`

**3. `check_dependencies` migliorato**
- Aggiunto warning (non error) per llm keys mancanti
- Link a documentazione llm setup
- Non blocca installazione, solo informa

### Modifiche README

**1. Struttura riorganizzata**
```
- Project Overview
- Requirements (SPOSTATO PRIMA)
- LLM Configuration (NUOVO)
- Installation
- Verify Installation (NUOVO)
- Usage
- Options
- Examples
```

**2. Sezione Requirements**
- Comandi install per Ubuntu/Debian
- Comandi install per Fedora/RHEL
- Comandi install per Arch Linux
- Riferimento a `make help_install`

**3. Sezione LLM Configuration (CRITICA)**
- Spiegazione necessità API keys
- Setup OpenAI e Anthropic
- Comando verifica (`llm "test" -m gpt-4o-mini`)
- Link documentazione completa

**4. Sezione Installation migliorata**
- Option 2 rinominata: "Run from Repository (No Install)"
- Chiarito uso sudo automatico in `make install`
- Step numerati con riferimenti a sezioni prerequisiti

**5. Sezione Verify Installation (NUOVA)**
- Test con `make test`
- Test manuale con comando
- Troubleshooting comune (3 scenari)

### Fix Tecnici

**1. Checksum file aggiornato**
- `qv.sh.sha256` ora contiene hash corretto di `scripts/qv.sh`
- Procedura verifica in README confermata funzionante

### Impatto UX

**Prima**: utente installa, poi scopre dipendenze mancanti, poi scopre llm non configurato
**Dopo**: Requirements → LLM Config → Install → Verify

**Flow ottimale ora**:
1. Leggi Requirements e installa deps
2. Configura llm keys (PRIMA di installare)
3. make install (con check automatico)
4. make test (verifica funzionamento)

### Test Suggeriti

```bash
# Test installazione pulita
cd /tmp
git clone https://github.com/aborruso/video_questions.git
cd video_questions
make help_install  # mostra comandi
make check_dependencies  # verifica deps + warning llm
make install  # installa script
make test  # verifica funzionamento
```
