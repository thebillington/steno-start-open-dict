# Generator rules and briefs layer

This document is the `steno-start-rules` source. It records how the generator
turns CMUdict pronunciation plus the open Stenotype chart into a single-stroke
outline, and how the documented briefs layer is applied.

The generator code is MIT. The generated dictionary data is CC BY-SA 4.0.

## Inputs and source ids

| Source id | Use |
|---|---|
| `cmudict` | Pronunciation, stress and phones only |
| `wikipedia-stenotype` | 22-key layout, chord chart, examples such as `KAT`, `PWET`, `RAOD`, `KAUPL` |
| `plover-wiki-top-100` | Published standard-form brief examples |
| `plover-wiki-brief-ideas` | Published patterns such as `P*EUFP` for *picture* and `-FRP` for *-mp* |
| `plover-wiki-cheat-sheets` | General theory/learning context only; no per-entry outline is taken from it |
| `plover-wiki-theory` | General theory context only; no per-entry outline is taken from it |
| `art-of-chording-website` | Archived theory, chord examples and briefs; the archived site footer states CC BY-SA 4.0 |
| `steno-start-word-list` | The authored 500-word selection |
| `steno-start-rules` | This document: the rule engine and the small Steno Start briefs layer |

Art of Chording is read only from the Wayback archive indexed by
`sources/art-of-chording/web-archive/pages.json`. Exact steno forms are taken
from the archived page text; conceptual homophone illustrations that are not
written in the steno alphabet are not treated as outlines. The archived site
footer is the licence evidence: "Licensed CC BY-SA 4.0 | © 2017-2026 by Thea
Morin".

## Steno order

The engine uses the 22-key order:

```
S- T- K- P- W- H- R- A O * -E -U -F -R -P -B -L -G -T -S -D -Z
```

Key ids are positions `0..21`. A stroke is a set of key ids; the formatter writes
them in this order and only puts a leading `-` when the first selected key is
right-hand.

## Pronunciation rules

For each word the generator:

1. reads the preferred CMUdict pronunciation (a small documented variant table
   selects the verb sense of `live`, `read`, `lead`, `close` and `use`; `use`
   is the verb `/juːz/` and is written `AOUZ`);
2. chooses the **last primary-stressed vowel** as the nucleus (falling back to
   the last secondary stress, then the first vowel);
3. maps consonants before the nucleus to the left-hand onset;
4. maps the nucleus to the vowel group;
5. maps consonants after the nucleus to the right-hand coda;
6. folds the result into one chord.

This is deliberately a one-chord teaching rule. It is not a syllable-by-syllable
Plover spelling and it does not claim Plover accuracy.

### Onset consonants

| Phoneme | Keys | Example |
|---|---|---|
| B | PW | bet `PWET` |
| CH | KH | chat `KHAT` |
| D | TK | dug `TKUG` |
| DH | TH | those `THOEZ` |
| F | TP | for `TPOR` |
| G | TKPW | get `TKPWET` |
| HH | H | hat `HAT` |
| JH | SKWR | jet `SKWRET` |
| K | K | cat `KAT` |
| L | HR | let `HRET` |
| M | PH | met `PHET` |
| N | TPH | net `TPHET` |
| P | P | pet `PET` |
| R | R | rat `RAT` |
| S | S | set `SET` |
| SH | SH | shut `SHUT` |
| T | T | top `TOP` |
| TH | TH | that `THA` |
| V | SR | vet `SRET` |
| W | W | wet `WET` |
| Y | KWR | yet `KWRET` |
| Z | S* | zap `S*AP` |

`Y` + `UW` is treated as the long-u vowel `AOU`, not as a separate onset
(`music`, `cute`, `use`). An unstressed `ER` before the nucleus contributes its
`R` to the onset (`around`, `direct`).

### Vowels

| CMU phoneme | Default keys | Notes |
|---|---|---|
| AA | A or O | `O` when the spelling has `o`; `AU` for `al`/`aw`/`au` |
| AE | A | short a |
| AH | U | schwa/short u |
| AO | O or AU | `AU` for `aw`/`au`/`all`/`al` and initial `wa`/`wo`; `AO` for `oo` |
| AW | OU | cow, out, house |
| AY | AOEU | time, right |
| EH | E or AE | `AE` for `ea` and `air` |
| ER | ER, EUR, UR or OR | authored r-coloured mapping: `EUR` for `ir`/`ear`; `UR` for `ur`; `OR` for `or`; otherwise `ER` |
| EY | AEU | day, make |
| IH | EU | sit, fish |
| IY | AOE | see, tree; a final unstressed `-y` adds the `E` marker |
| OW | OE | home, boat |
| OY | OEU | boy, coin |
| UH | AO or U | `AO` for `oo`/`o`; `U` for `u` (`put`, `pull`, `push`) |
| UW | AO or AOU | `AO` for `oo`; `AOU` otherwise (`blue`, `lose`) |

Spelling adjustments are intentionally small and documented:

- final unstressed `IY` adds `E` to the vowel group (`only` `OEPBL`, `family`
  `TPAEPL`, `happy` `HAEP`);
- a final consonant `L` after `T` in `-le` drops the `T` (`little` `HREUL`);
- a final `L` after `K`/`G` in `-le` drops the `L` (`circle` `SEURBG`);
- initial silent written letters are restored from orthography: `wr-` adds `W`
  (`write` `WRAOEUT`), `kn-` adds `K`, `gn-` adds `G`, `ps-`/`pn-` add `P`, and
  an initial written `h` before a vowel adds `H` (`hour` `HOUR`).

### Coda consonants

| Phoneme | Keys | Example |
|---|---|---|
| B | B | lab |
| CH | FP | latch |
| D | D | lad |
| F | F | laugh |
| G | G | lag |
| JH | PBLG | ledge |
| K | BG | lack |
| L | L | lull |
| M | PL | lamb |
| N | PB | lain |
| NG | PBG | long |
| P | P | lap |
| R | R | liar |
| S | S | lass |
| SH | RB | lash |
| T | T | let |
| TH | *T | lathe |
| V | *F | leave |
| Z | Z | craze |

Greedy merge rules cover the chart clusters: `-mp` `FRP`, `-nch` `FRPBLG`,
`-ng`+`K` `*PBG`, `-rch` `FRPB`, `-rf`/`-rv` `FRB`, `-st` `FT`, `-sm` `FPL`,
`-x` `BGS`, `-dz` `DZ`, and `-pl` `PL`.

## Briefs layer

Briefs are applied before rules, in source-list order, and their chords are
reserved so a later rule cannot steal them.

1. **Plover Wiki Top 100** (`plover-wiki-top-100`): the published examples for
   the common words in the list. Canonical engine forms are used where the wiki
   writes a trailing dash (`SKP-` -> `SKP`, `TPR-` -> `TPR`). The wiki's
   `for` form `TP-R` is not used because its canonical form `TPR` is the
   dictionary form for `from`; `for` instead uses the rule form `TPOR`.
2. **Plover Wiki Brief Ideas** (`plover-wiki-brief-ideas`): the published
   `-ture` example `P*EUFP` for *picture*. The `-FRP` for `-mp` pattern is
   reflected in the coda table.
3. **Art of Chording archive** (`art-of-chording-website`): exact forms from the
   archived pages. Briefs: `are` `R` (`layout/bottom-row`), `every` `EFR`,
   `always` `AULS` and `remember` `RER`
   (`introduction/how-steno-works`), `around` `ARPBD`
   (`multistroke/prefixes-and-suffixes`), and `paper` `PAEUP` plus `air` `AEUR`
   (`sounds/ay_oy`). Exact phonetic examples that already agree with the rules
   are cited per entry rather than duplicated as special cases: `cat` `KAT`,
   `rat` `RAT`, `start` `START`, `laugh` `HRAF`, `pay` `PAEU`, `stay` `STAEU`
   and `oil` `OEUL`. AoC's `OUT/SEUD` for *outside* is recorded as the optional
   multi-stroke form.
4. **Steno Start briefs** (`steno-start-rules`): a small, explicitly documented
   set for number words and homophone collisions that the plain rule would
   otherwise merge. Examples: `today` `TOED`, `four` `TPAOR`, `many` `PHAEPB`
   (the plain form is `PHEPB`, *men*), `open` `OEP`, `city` `STEUS`,
   `hear` `HAO*ER`, and `road` `RAOD` (the Wikipedia chart's own `road`
   example). `ever` is not briefed: the plain rule already gives `*EFR`, while
   the AoC `every` brief `EFR` avoids the collision. No collision is recorded
   for `ever`.

There is deliberately **no complete 500-word table**. The generator contains
tables of phonemes, spelling adjustments and briefs; all other words are
derived from their CMUdict pronunciation.

## Collision handling

The dictionary must have 500 unique signatures. Candidates are tried in this
order:

1. the plain rule chord;
2. the merged-vowel chord (folds an initial unstressed vowel into the vowel
   group, used for example when `along` would otherwise equal `long`);
3. the same chord with an unused asterisk;
4. the same chord with one unused right-hand tag, in the fixed order
   `D Z G S T B L P R F`;
5. a deterministic combination of right-hand tags.

Only the first three are common. Every non-plain choice is recorded as
`changed: true`, with `collisionResolved` and the chosen `variant` in
`provenance/entries.json`.

The AoC briefs are reserved before the rule pass. The `every` brief `EFR`
avoids the plain-rule `*EFR` that it would otherwise share with `ever`. Both
forms come from the documented rules; `every` is a brief, `ever` is not, and
neither is recorded as a collision.

## Multi-stroke layer

`data/dictionary.json` contains one stroke for every one of the 500 words.
`data/multi_stroke.json` is an optional expansion layer. It is produced for
non-brief words that have at least two stressed vowels; the generator splits the phone
string near the second stressed vowel, builds each part with the same rules and
writes `STROKE/STROKE`. The AoC `OUT/SEUD` form for *outside* is used when the
archive supplies it. The single-stroke teaching form remains the dictionary
entry. No word requires the multi-stroke form to be covered.

## Known limitations

- A single chord has a fixed key order. Multi-consonant codas are packed into
  the available right-hand keys, so a coda can be compressed or reordered
  relative to the phone list in the provenance. `music` (`Z K`) and `animal`
  (`N M L`) are examples. The phone list is the derivation record, not a claim
  that every phone has its own key.
- A few collisions use an asterisk even though the words are not homophones:
  `certain` `S*ERPBT`, `corner` `KO*RPB` and `cross` `KRO*S`. These are
  documented teaching compromises, not Plover-compatible forms.
- The `-le` elisions (`little` `HREUL`, `circle` `SEURBG`) and the silent-letter
  restorations are authored Steno Start spelling rules. The chart does not
  supply them.
- The `ER`/r-coloured vowel row is authored because the cited chart has no `ER`
  row.
- The current 500-word set matches 392/500 (78.4%) of the full external Plover
  reference exactly. Exact personal Plover compatibility comes from importing
  the user's own dictionary, not from these built-in banks.

## Provenance and licence

Each entry records `sourceIds`, the rule/source description, its CMUdict
pronunciation, the chosen variant, and whether it changed from the plain rule.
The dictionary data is CC BY-SA 4.0. The generator is MIT. No GPL dictionary,
Plover `main.json` or proprietary dictionary is read or included. The Plover
Wiki pages are public theory references, not the GPL dictionary file.
