# Plover compatibility report

**Date:** 2026-10-29
**Dictionary:** `data/dictionary.json`
**Generator:** clean-lab build at `53c5dee`
**Reference:** pinned 500-word Plover-compatible teaching set from Steno Start commit `322d212`

## Method

The generator received only the open sources in this lab. It was not given any
Plover score, category feedback, expected outlines, or failing words. This report
was produced by the parent evaluator after the build, as a single black-box
comparison.

## Results

| Metric | Result |
|---|---:|
| Words compared | 500 |
| Exact signature match | 324 / 500 = 64.8% |
| Mean key-set Jaccard | 0.862 |
| Coverage | 500 / 500 |

Primary mismatch categories:

| Category | Words |
|---|---:|
| vowel | 42 |
| coda | 38 |
| onset + vowel + coda | 19 |
| vowel + coda | 18 |
| onset | 14 |
| vowel + star | 10 |
| star + coda | 9 |
| onset + vowel | 7 |
| star | 6 |
| vowel + star + coda | 6 |
| other combined | 11 |

## Interpretation

This is a custom open-source-derived teaching dictionary. It shares the 22-key
layout and many Plover-style forms, but it is not a Plover dictionary and is not
claimed to be Plover-compatible. The 64.8% figure is the exact agreement with
this pinned teaching set, not a general claim about all of Plover.

The dictionary is useful as a beginner teaching set and as the first bank in
Steno Start. Importing a user's own Plover dictionary is the supported route to
exact personal Plover compatibility.
