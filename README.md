# open-steno-dict

An openly licensed English steno dictionary for Steno Start.

This repository is the public source of truth for the dictionary data, the
generator, the source ledger and the validation report. It is independent and is
not affiliated with, endorsed by, or maintained by Open Steno or Plover.

## Licence

- Dictionary data: CC BY-SA 4.0
- Generator code: MIT
- CMUdict input: BSD-2-Clause
- Third-party source extracts: their original licences, recorded in `NOTICE`
  and `provenance/`

The data and code are licensed separately. See `LICENSE`, `LICENSES/` and
`NOTICE`.

## What is here

| Path | Purpose |
|---|---|
| `data/` | Source word list, generated dictionary, multi-stroke forms, manifest |
| `generator/` | Deterministic rules, briefs and generator source |
| `sources/` | Source registry and allowed reference extracts |
| `provenance/` | Per-entry source records, hashes and build metadata |
| `validation/` | Accuracy report against the pinned Plover reference |
| `scripts/` | Build, export and licence checks |
| `LICENSES/` | Full licence texts |
| `.github/workflows/` | CI for build, tests, provenance and licence checks |

## Rules

- No GPL steno dictionary data is included.
- No Plover `main.json` or derivative.
- Every dictionary entry must point to a source and licence.
- Every build must be reproducible from the hashes and command in
  `provenance/build.json`.
- The dictionary data is CC BY-SA 4.0. The app code is a separate work.

## Status

Scaffold only. The dictionary and generator are being built.
