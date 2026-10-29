# Three-round source accuracy review

Date: 2026-10-29

Target: accuracy against the sources in this repository (CMUdict, Wikipedia
Stenotype chart, Plover Wiki pages, Art of Chording archive, authored rules and
word list). Plover compatibility is measured separately and is not used to
choose outlines.

The regression rule: a change is accepted only when it fixes a source
contradiction. A change that only improves Plover compatibility is not accepted
as a source fix. Arbitrary choices are not changed; they are listed for a human
decision.

## Round 1: baseline source review

Full external Plover reference:

| Bank | Words | In reference | Exact | Exact, all |
|---|---:|---:|---:|---:|
| Basics | 500 | 500 | 391 | 78.2% |
| Everyday | 500 | 500 | 327 | 65.4% |
| Legal | 200 | 199 | 59 | 29.5% |
| Business | 199 | 197 | 71 | 35.7% |
| General | 500 | 142 | 23 | 4.6% |

Source review findings:

- 4 entries cited the word list as outline support: `hear`, `open`, `today`,
  `city`. The word list only supports word selection.
- `door` was forced to `TKAUR` by a special case, although the documented `oo`
  spelling rule gives `TKAOR`.
- No structural failures: all outlines parsed, signatures matched, hashes and
  source ids were valid.

Accepted source fixes: `door` back to `TKAOR`; remove the four word-list
citations. No other changes.

## Round 2: post-fix source review

| Bank | Words | In reference | Exact | Exact, all |
|---|---:|---:|---:|---:|
| Basics | 500 | 500 | 392 | 78.4% |
| Everyday | 500 | 500 | 328 | 65.6% |
| Legal | 200 | 199 | 59 | 29.5% |
| Business | 199 | 197 | 71 | 35.7% |
| General | 500 | 142 | 23 | 4.6% |

Source review: 0 issues. The remaining flags are known structural limits or
arbitrary decisions, not source violations:

- multi-phone codas packed into one chord
- non-homophone asterisk collisions
- authored `-le` elision and `ER` row

No compatibility-only changes were made.

## Round 3: regression check

| Bank | Words | In reference | Exact | Exact, all |
|---|---:|---:|---:|---:|
| Basics | 500 | 500 | 392 | 78.4% |
| Everyday | 500 | 500 | 328 | 65.6% |
| Legal | 200 | 199 | 59 | 29.5% |
| Business | 199 | 197 | 71 | 35.7% |
| General | 500 | 500 | 215 | 43.0% |

Source review: 0 issues.

Round 3 kept the Basics, Everyday, Legal and Business results identical to round
2, and replaced General with NGSL ranks 501-1000 after the product decision.
There was no oscillation in the reviewed banks. The
only data change across the three rounds was the source-supported `door` fix
and the source-citation cleanup. The target, source accuracy, moved from 4
review issues to 0; full compatibility moved from 391 to 392 exact Basics words.

## Open decisions

These are not determined by the cited sources and were not changed:

1. Non-homophone asterisk collisions, for example `certain` `S*ERPBT`,
   `corner` `KO*RPB`, `cross` `KRO*S`, `away` `WA*EU`.
2. `-le` elision: `little` `HREUL`, `circle` `SEURBG`.
3. Authored r-coloured `ER` mapping, which the chart does not contain.
4. `use` sense: verb `AOUZ` or noun `AOUS`.
5. General bank composition: replaced with NGSL ranks 501-1000 by decision. All
   500 words are present in the Plover reference.
6. Alternative published forms: `my`, `we`, `she`, `go`, `most`, `even`, `but`.
7. Multi-consonant coda packing: accept the single chord or require a
   multi-stroke form where the phone sequence cannot fit.
8. `four` `TPAOR` versus `TPAUR` or another number form.

Machine-readable round records are in `benchmarks/reviews/round-*.json`.
