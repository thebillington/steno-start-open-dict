# Lab build spec: open-licensed 500-word dictionary

You are working in an isolated lab. Use only the files in this directory.

## Purpose

Build an openly licensed 500-word steno dictionary for Steno Start. It must be
derived from the provided open sources, carry per-entry provenance, and be
shippable under CC BY-SA 4.0 for the data. The generator code is MIT.

Steno Start is independent and is not affiliated with Open Steno or Plover.

## Allowed material

- `sources/cmudict/cmudict.dict`: CMUdict, BSD-2-Clause. Pronunciation only.
- `sources/art-of-chording/web-archive/`: Art of Chording, CC BY-SA 4.0, website footer. Theory, chord examples and briefs.
- `sources/wikipedia/stenotype.wiki`: CC BY-SA 4.0. Layout, chart, examples.
- `sources/plover-wiki/*.wiki`: CC BY as stated in the Plover Wiki footer.
  These are public Plover-theory references, not the GPL `main.json` file.
- `data/source_words.txt`: the authored 500-word list.
- `engine/`: the clean-room parser/formatter/validator, MIT.
- `LICENSES/`: full licence texts.

No other material is allowed. Do not read `/home/dev/Development/steno`, any
compatibility/lexicon repository, any Plover dictionary file, any GPL steno
dictionary, or any other steno engine source.

## Deliverables

Create a deterministic Dart generator in `generator/`:

- path dependency on `../engine`;
- reads the provided sources;
- produces `data/dictionary.json` with all 500 words and one stroke each;
- produces `data/multi_stroke.json` for words needing more than one stroke;
- produces `data/manifest.json` with counts and hashes;
- produces `provenance/entries.json` with one record per word:
  - word, outline, sourceIds, rule/source description, changed flag;
- produces `provenance/build.json` with:
  - generator commit/version, command, input file hashes, output hashes, date;
- produces `validation/self_check.md` with parse, key-count, duplicate-key,
  uniqueness and coverage results.

`sourceIds` must use the ids in `sources/sources.json`. Every entry must have at
least one source id. The dictionary must be licensed CC BY-SA 4.0; the generator
code is MIT.

## Engineering rules

- Use the Plover Wiki Top 100 and Brief Ideas pages as open brief/theory
  references where useful. Cite them per entry.
- Use CMUdict for pronunciation and the Wikipedia chart for the layout.
- Do not hardcode a complete 500-word table. The generator must contain rules and
  a briefs layer, with the open wiki references documented.
- Do not invent a source. If an outline is derived from our rules, use the
  `steno-start-rules` source id.
- If a word cannot be generated, report it rather than inventing a hidden answer.
- Do not run a network request. Do not use Docker mounts outside this lab.
- No Plover backtest is available to you. The parent will run the black-box
  validation and write `validation/report.md`.

## Build and test

Dart is not installed on the host. Use the dev container:

```sh
docker run --rm -v /home/dev/Development/steno-start-open-dict-lab:/workspace \
  -w /workspace/generator revision-app-dev:latest \
  sh -lc 'dart pub get && dart run bin/generate.dart && dart test'
```

Record the exact command in `provenance/build.json`.

## Isolation

Do not read anything outside this directory. If you encounter forbidden
material, stop and report it. Do not fetch Plover, Lapwing, Typey Type or any
steno dictionary. The only steno code is `engine/`.
