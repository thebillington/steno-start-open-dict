# Three-round source accuracy review, cycle 2

Date: 2026-10-29

Target: accuracy against the sources in this repository. Plover compatibility is
measured separately and is not used to choose outlines.

Changes are accepted only when a cited source supports them. Each round is
measured before the next change. A change that breaks a source test or lowers
any bank is reverted.

## Round 1: suffix clusters

Source support:

- Plover Wiki Cheat Sheet: -tion/-sion/-cian/-cean/-gion use -GS; -ction uses
  -BGS; -lk uses -LG.
- Plover Practice, The -ion and -tion endings: -GS, -BGS, -ation.
- Plover Practice, The -ment suffix: -PLT.
- Learn Plover, Lesson 5: compound clusters should be used where possible.

Implemented:

- final SH N, ZH N, JH N -> GS
- final K SH N -> BGS
- final M N T -> PLT

Results:

| Bank | Exact | Exact, all |
|---|---:|---:|
| Basics | 393 | 78.6% |
| Everyday | 331 | 66.2% |
| Legal | 63 | 31.5% |
| Business | 78 | 39.2% |
| General | 225 | 45.0% |

## Round 2: wh and -lk

Source support:

- Plover Wiki Top 100: WHA for what, WHO for who, WH for when.
- Plover Wiki Cheat Sheet: -lk uses -LG.
- Plover Practice, common prefixes and suffixes: suffix keys can be folded into
  a single stroke.

Implemented:

- written wh- uses W plus H
- final K L and L K -> LG

Results:

| Bank | Exact | Exact, all |
|---|---:|---:|
| Basics | 394 | 78.8% |
| Everyday | 335 | 67.0% |
| Legal | 63 | 31.5% |
| Business | 79 | 39.7% |
| General | 228 | 45.6% |

No bank regressed.

## Round 3: -ing after T and D

Source support:

- Art of Chording, Prefixes and suffixes: -G is ^ing, and Plover folds the
  suffix into the preceding stroke.
- Learn Plover, Lesson 7: -G is a suffix key with automatic folding.

Implemented:

- final T NG -> GT
- final D NG -> GD

Results:

| Bank | Exact | Exact, all |
|---|---:|---:|
| Basics | 394 | 78.8% |
| Everyday | 335 | 67.0% |
| Legal | 63 | 31.5% |
| Business | 80 | 40.2% |
| General | 228 | 45.6% |

No bank regressed. Business gained one word.

## Rejected change

A blanket rule that words spelled with `ea` and pronounced /iː/ use the AE vowel
was tested and rejected. It changed `meat` from `PHAO*ET` to `PHAET` and broke
the source test. It was reverted before the bank build, so it never entered the
shipped data.

## Net change over the cycle

| Bank | Start | End | Change |
|---|---:|---:|---:|
| Basics | 392 | 394 | +2 |
| Everyday | 328 | 335 | +7 |
| Legal | 59 | 63 | +4 |
| Business | 71 | 80 | +9 |
| General | 215 | 228 | +13 |

Source review after round 3: 0 issues in all four generated banks.
