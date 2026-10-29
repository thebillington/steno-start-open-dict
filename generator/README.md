# Generator

Deterministic Dart generator for the Steno Start open 500-word dictionary.

- Generator code: MIT.
- Generated data: CC BY-SA 4.0.
- Engine dependency: path `../engine` (clean-room 22-key parser, MIT).
- No network access for steno data; no Plover `main.json`, GPL dictionary or
  proprietary dictionary input.
- Art of Chording is used only through the archived pages under
  `../sources/art-of-chording/web-archive/` (CC BY-SA 4.0 per the archived
  footer).

## Build

```sh
docker run --rm -v /home/dev/Development/steno-start-open-dict-lab-clean:/workspace \
  -w /workspace/generator revision-app-dev:latest \
  sh -lc 'dart pub get && dart run bin/generate.dart && dart test'
```

`bin/generate.dart` writes:

- `../data/dictionary.json`
- `../data/multi_stroke.json`
- `../data/manifest.json`
- `../provenance/entries.json`
- `../provenance/build.json`
- `../validation/self_check.md`

Use `dart run bin/generate.dart --check` to run the build without writing files.

## Structure

| Path | Purpose |
|---|---|
| `lib/src/cmudict.dart` | Tolerant CMUdict reader, stress and variant handling |
| `lib/src/rules.dart` | Phoneme -> key tables, spelling adjustments, one-chord rule and deterministic candidates |
| `lib/src/briefs.dart` | Documented briefs layer with per-brief source ids |
| `lib/src/generator.dart` | Orchestration, collision resolution, provenance, manifest, self-check |
| `RULES.md` | The `steno-start-rules` source: full rule and briefs documentation |
| `test/generator_test.dart` | Build, coverage, uniqueness, provenance, fidelity and determinism tests |

## Rules in brief

1. Read the preferred CMUdict pronunciation. A small variant table chooses the
   verb sense of `live`, `read`, `lead`, `close` and `use`.
2. Keep the last primary-stressed vowel as the nucleus and fold surrounding
   consonants into the left-hand onset and right-hand coda.
3. Use the open Wikipedia Stenotype chart for the onset, main vowel, coda and
   cluster tables. The r-coloured `ER` row is an authored Steno Start rule.
4. Apply a small spelling layer: `ea`/`air`, final `-y`, `oo`, `-le`, silent
   `wr`/`kn`/`gn`/`ps`/`pn`/initial `h`, and the `oa` `road` example.
5. Apply the documented briefs layer before rules.
6. Resolve the few remaining collisions deterministically with a merged vowel,
   an asterisk or a right-hand tag, and record the choice.

There is no complete 500-word table. `RULES.md` documents the groups, rules and
authored briefs; `provenance/entries.json` records the derivation and source ids
for each word.

## Source ids

The generator only uses ids in `sources/sources.json`:

- `cmudict`
- `wikipedia-stenotype`
- `plover-wiki-top-100`
- `plover-wiki-brief-ideas`
- `plover-wiki-cheat-sheets` (theory context only)
- `plover-wiki-theory` (theory context only)
- `art-of-chording-website` (archived examples and briefs)
- `steno-start-word-list`
- `steno-start-rules`

## Accuracy

The self-check proves structural validity: every stroke parses, has 1-22 keys,
has no duplicate physical key, all 500 signatures are unique and every source
word is covered. It does **not** claim Plover accuracy. The parent project runs
the pinned black-box comparison and writes `validation/report.md`.
