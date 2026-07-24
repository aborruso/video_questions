# Releasing

Procedura di riferimento per ogni nuova release e subrelease di `video-questions` (comando `vq`).

## Versioning

Si usa [SemVer](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **PATCH** (`0.2.1` → `0.2.2`) — subrelease: bugfix, fix diagnostici, doc, nessun cambio d'uso.
- **MINOR** (`0.2.x` → `0.3.0`) — nuove funzionalità retrocompatibili (nuovo flag, nuova modalità).
- **MAJOR** (`0.x` → `1.0.0`) — breaking change nell'interfaccia CLI.

La versione vive **solo** in `pyproject.toml`. `vq --version` la legge a runtime via `importlib.metadata.version("video-questions")`, quindi non ci sono stringhe da aggiornare nel codice.

## Prerequisiti (una tantum)

- `uv` per build e install locale.
- `twine` con token PyPI già in `~/.pypirc` (`[pypi]`, `username = __token__`).
- `gh` autenticato su `github.com` (`gh auth status`).
- Remote `origin` → `https://github.com/aborruso/video_questions.git`.

## Passi

Sostituire `X.Y.Z` con la versione target (es. `0.2.2`).

### 1. Bump versione

Aggiornare `version` in `pyproject.toml`:

```toml
version = "X.Y.Z"
```

### 2. Aggiornare LOG.md

Nuova voce in cima, data `YYYY-MM-DD`, bullet ad alto segnale con la versione tra parentesi. Aggiornare anche README/CLAUDE.md se cambiano requisiti o comportamento.

### 3. Reinstallare il CLI locale e verificare

```bash
uv tool install --reinstall .
vq --version          # deve stampare: vq X.Y.Z
```

Provare almeno un percorso reale (es. `vq <URL> --metadata`) per confermare che non si è rotto nulla.

### 4. Build

```bash
rm -rf dist
uv build
```

Produce `dist/video_questions-X.Y.Z-py3-none-any.whl` e `.tar.gz`.

### 5. Commit

```bash
git add -A pyproject.toml LOG.md README.md src/
git commit -m "release: X.Y.Z — <sintesi>"
```

### 6. Pubblicare su PyPI

```bash
twine check dist/video_questions-X.Y.Z*
twine upload dist/video_questions-X.Y.Z*
```

Verifica:

```bash
curl -s https://pypi.org/pypi/video-questions/json | python3 -c "import sys,json;print(json.load(sys.stdin)['info']['version'])"
```

> PyPI **non** consente di riusare un numero di versione: un upload sbagliato brucia quel numero, si passa al successivo.

### 7. Push e tag su GitHub

Il tag segue la convenzione `vX.Y.Z` (prefisso `v`).

```bash
git push origin main
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

### 8. GitHub Release

Creare la release associata al tag, con note derivate dalla voce di LOG.md:

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z" \
  --notes "<note della release, es. copiate dalla voce LOG.md>" \
  dist/video_questions-X.Y.Z-py3-none-any.whl \
  dist/video_questions-X.Y.Z.tar.gz
```

In alternativa, generare le note automaticamente dai commit dall'ultimo tag:

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --generate-notes \
  dist/video_questions-X.Y.Z*
```

## Checklist rapida

- [ ] `version` bumpata in `pyproject.toml`
- [ ] `LOG.md` aggiornato (+ README/CLAUDE.md se serve)
- [ ] `uv tool install --reinstall .` + `vq --version` corretto
- [ ] `uv build` pulito
- [ ] commit `release: X.Y.Z`
- [ ] `twine check` PASSED + `twine upload`
- [ ] versione visibile su PyPI
- [ ] `git push origin main`
- [ ] tag `vX.Y.Z` creato e pushato
- [ ] GitHub Release creata con gli artefatti allegati
