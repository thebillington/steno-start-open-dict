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

The source registry is `sources/sources.json`. It records the source id, URL,
licence, file, SHA-256 and intended use.

Allowed inputs:

- CMUdict, BSD-2-Clause, pronunciation only.
- Wikipedia: Stenotype, CC BY-SA 4.0.
- Plover Wiki pages listed in the registry, CC BY as stated in the wiki footer.
- The Steno Start authored 500-word list.
- The local `steno-start-rules` document (`generator/RULES.md`), CC BY-SA 4.0.
- Art of Chording, CC BY-SA 4.0 per the archived website footer. The archived
  pages and evidence are in `sources/art-of-chording/web-archive/`.

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
| `validation/` | Generated self-check; the parent adds the black-box report |
| `scripts/` | Build, export and licence checks |
| `LICENSES/` | Full licence texts |
| `.github/workflows/` | CI for build, tests, provenance and licence checks |

## Generated dictionary

| File | Contents |
|---|---|
| `data/dictionary.json` | Flat `word -> single stroke` map for all 500 words |
| `data/multi_stroke.json` | Optional `word -> STROKE/STROKE` expansions for words with more than one stressed vowel |
| `data/manifest.json` | Counts, source list, output hashes and the exact build command |
| `provenance/entries.json` | One record per word: outline, signature, source ids, rule/source description, changed flag |
| `provenance/build.json` | Generator version/commit, command, date, input hashes and output hashes |
| `validation/self_check.md` | Parse, 1-22 key, duplicate-key, uniqueness and coverage proofs |

The generated dictionary has 500 unique single-stroke signatures: 104 brief
entries and 396 rule-derived entries, with 4 documented collision
disambiguations. Some rule-derived entries also cite an exact Art of Chording
example. `data/multi_stroke.json` currently has 8 optional expansions; no word
requires a multi-stroke form to be covered.

The generator does not claim accuracy against Plover or any other dictionary.
The current 500-word bank matches 319/500 (63.8%) of the pinned reference
exactly; see `validation/report.md` and `benchmarks/results.json`.
It is a rule-based, open-source derivation. The parent project runs the pinned
black-box comparison and writes `validation/report.md`.

## Build

Dart is not installed on the host. The documented build and test command is:

```sh
docker run --rm -v /home/dev/Development/steno-start-open-dict-lab-clean:/workspace \
  -w /workspace/generator revision-app-dev:latest \
  sh -lc 'dart pub get && dart run bin/generate.dart && dart test'
```

`generator/RULES.md` documents the phoneme rules, spelling adjustments, the
briefs layer and the deterministic collision handling.

## Build rules

- Every entry must point to one or more source ids.
- No GPL steno dictionary data.
- No entry without a source and licence.
- The build must be reproducible from `provenance/build.json`.
- The app asset is exported from this repo, not hand-edited.

## Status

The generator, dictionary, provenance and self-check are built. The parent
project runs the black-box Plover comparison and writes the accuracy report.
