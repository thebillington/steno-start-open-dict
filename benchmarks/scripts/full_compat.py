#!/usr/bin/env python3
"""Score every word in a generated bank against a full external dictionary.

The reference is not shipped and is never passed to the generator. This script
is an evaluation tool only.

Example:
  python3 benchmarks/scripts/full_compat.py \
    --reference /tmp/main.json \
    --bank benchmarks/banks_data/everyday/dictionary.json \
    --name everyday
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

KEYS = list("STKPWHRAO*EUFRPBLGTSDZ")
RIGHT_START = 12


def parse_stroke(stroke: str) -> tuple[int, ...]:
    i = 0
    ids: list[int] = []
    for ch in stroke.strip().upper():
        if ch == "-":
            i = max(i, RIGHT_START)
            continue
        while i < len(KEYS) and KEYS[i] != ch:
            i += 1
        if i >= len(KEYS):
            raise ValueError(stroke)
        ids.append(i)
        i += 1
    return tuple(sorted(set(ids)))


def signature(stroke: str) -> str:
    return "|".join(map(str, parse_stroke(stroke)))


def outline_signature(outline: str) -> tuple[str, ...] | None:
    try:
        return tuple(signature(part) for part in outline.split("/"))
    except ValueError:
        return None


def load_reference(path: Path) -> dict[str, list[tuple[str, ...]]]:
    raw = json.loads(path.read_text())
    reference: dict[str, list[tuple[str, ...]]] = {}
    for strokes, word in raw.items():
        word = str(word).strip().lower()
        if not word or " " in word:
            continue
        if not re.fullmatch(r"[a-z][a-z'.-]*", word):
            continue
        sig = outline_signature(str(strokes))
        if sig is None:
            continue
        reference.setdefault(word, []).append(sig)
    return reference


def score_bank(
    bank: dict[str, str],
    reference: dict[str, list[tuple[str, ...]]],
) -> dict[str, object]:
    exact = 0
    present = 0
    mismatch_single = 0
    multi_only = 0
    missing: list[str] = []
    mismatches: list[dict[str, object]] = []
    for word, outline in bank.items():
        refs = reference.get(word.lower())
        if not refs:
            missing.append(word)
            continue
        present += 1
        generated = (signature(outline),)
        if any(candidate == generated for candidate in refs):
            exact += 1
            continue
        if any(len(candidate) == 1 for candidate in refs):
            mismatch_single += 1
        else:
            multi_only += 1
        mismatches.append(
            {
                "word": word,
                "generated": outline,
                "reference_signatures": sorted({"/".join(c) for c in refs}),
            }
        )
    words = len(bank)
    return {
        "words": words,
        "present": present,
        "missing": len(missing),
        "missing_words": missing[:50],
        "exact": exact,
        "exact_percent_all": round(100 * exact / words, 1) if words else 0.0,
        "exact_percent_present": round(100 * exact / present, 1) if present else 0.0,
        "mismatch_single": mismatch_single,
        "multi_only": multi_only,
        "mismatch_sample": mismatches[:25],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", required=True)
    parser.add_argument("--bank", required=True)
    parser.add_argument("--name", default="bank")
    parser.add_argument("--out")
    args = parser.parse_args()

    reference = load_reference(Path(args.reference))
    bank = {
        str(k).strip().lower(): str(v).strip()
        for k, v in json.loads(Path(args.bank).read_text()).items()
    }
    result = {"name": args.name, **score_bank(bank, reference)}
    print(json.dumps(result, indent=2))
    if args.out:
        Path(args.out).write_text(json.dumps(result, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
