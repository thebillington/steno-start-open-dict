# steno-start-open-dict

An openly licensed English steno dictionary for **Steno Start**.

## Purpose

This repository derives a teaching dictionary from openly licensed material so
it can be shipped inside the Steno Start application without bundling Plover's
GPL dictionary.

The goal is not to copy Plover. The goal is to build the most compatible
open-licensed dictionary we can from public steno references and CMUdict, then
measure the result against a pinned Plover reference as a black box.

Steno Start is independent and is not affiliated with, endorsed by, or
maintained by Open Steno or Plover.

## Licence

| Part | Licence |
|---|---|
| Dictionary data in `data/` and derived provenance in `provenance/` | CC BY-SA 4.0 |
| Generator code in `generator/` | MIT |
| Clean engine in `engine/` | MIT |
| CMUdict in `sources/cmudict/` | BSD-2-Clause |
| Wikipedia and Plover Wiki extracts | their original CC licences |
| Full licence texts | `LICENSES/` |

The dictionary data and code are separate works. The app can be paid, but the
dictionary data must remain available under CC BY-SA 4.0. See `NOTICE`.

## Sources

The source registry is `sources/sources.json`. External source files are not committed; run `python3 scripts/fetch_sources.py` to download them into the ignored `sources/cache/` directory and verify their SHA-256 hashes. It records the source id, URL,
licence, file, SHA-256 and intended use.

Allowed inputs:

- CMUdict, BSD-2-Clause, pronunciation only.
- Art of Chording, CC BY-SA 4.0, https://www.artofchording.com/.
- Wikipedia: Stenotype, CC BY-SA 4.0.
- Plover Wiki pages listed in the registry, CC BY as stated in the wiki footer.
- The Steno Start authored 500-word list.

Excluded:

- Plover `main.json` and any GPL dictionary.
- Typey Type, Lapwing, StenEd, Magnum, Phoenix and other dictionaries.

The Plover Wiki pages are public Plover-theory references, not the GPL
dictionary file. Page-level provenance and licence should be reviewed before
commercial release.

## Layout

| Path | Purpose |
|---|---|
| `data/` | Source word list, generated dictionary, multi-stroke forms, manifest |
| `generator/` | Deterministic rules, briefs and generator source |
| `engine/` | Clean-room 22-key parser and validator |
| `sources/` | Source registry and open source extracts |
| `provenance/` | Per-entry source records, hashes and build metadata |
| `validation/` | Accuracy report against the pinned Plover reference |
| `scripts/` | Build, export and licence checks |
| `LICENSES/` | Full licence texts |
| `.github/workflows/` | CI for build, tests, provenance and licence checks |

## Build rules

- Every entry must point to one or more source ids.
- No GPL steno dictionary data.
- No entry without a source and licence.
- The build must be reproducible from `provenance/build.json`.
- The app asset is exported from this repo, not hand-edited.

## Status

Sources and licence structure are compiled. The generator and dictionary are
the next build.
