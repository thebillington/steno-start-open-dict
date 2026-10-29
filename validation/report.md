# Plover compatibility report

**Date:** 2026-10-29
**Dictionary:** `data/dictionary.json`
**Generator:** clean-lab audit build, 2026-10-29
**Reference:** full external Plover `main.json`, evaluation only, not shipped

## Method

The generator received only the open sources in this repository. It was not
given any Plover score, category feedback, expected outlines, or failing words.
This report was produced after the build as a black-box comparison.

Every bank word is in the denominator. A word is an exact match when the
generated stroke sequence matches any published outline for that word in the
reference. `present` is the number of bank words that the reference contains.

## Full bank results

| Bank | Words | In reference | Exact, all words | Exact, present |
|---|---:|---:|---:|---:|
| Basics 500 | 500 | 500 | 394 / 500 = 78.8% | 78.8% |
| Everyday 500 | 500 | 500 | 335 / 500 = 67.0% | 67.0% |
| Legal 200 | 200 | 199 | 63 / 200 = 31.5% | 63 / 199 = 31.7% |
| Business 200 | 199 | 197 | 80 / 199 = 40.2% | 80 / 197 = 40.6% |
| General 500 | 500 | 500 | 228 / 500 = 45.6% | 45.6% |

The General bank now uses NGSL ranks 501-1000. All 500 words are present in the
reference; the earlier random CMUdict sample was replaced.

The earlier 500-word teaching-subset comparison gave 319/500 (63.8%). That is a
narrower reference with a single outline per word. It is retained in
`benchmarks/results.json` and should not be compared with the full table above.

## Interpretation

This is a custom open-source-derived teaching dictionary. It shares the 22-key
layout and many Plover-style forms, but it is not a copy of Plover and does not
claim general Plover compatibility. The 78.8% figure is exact agreement with
the full external reference for the Basics bank.

The dictionary is useful as a beginner teaching set and as the first bank in
Steno Start. Importing a user's own Plover dictionary is the supported route to
exact personal Plover compatibility.
