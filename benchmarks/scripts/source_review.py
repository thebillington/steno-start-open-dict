#!/usr/bin/env python3
"""Audit generated bank entries against the repository sources.

This is a review instrument, not a generator input. It checks structural and
source-consistency invariants and reports items that need a human decision.

Example:
  python3 benchmarks/scripts/source_review.py \
    --bank-dir benchmarks/banks_data/everyday \
    --name everyday \
    --out benchmarks/reviews/round-1-everyday.json
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
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


def load_cmu(path: Path) -> dict[str, list[str]]:
    variants: dict[str, list[str]] = {}
    for line in path.read_text().splitlines():
        if not line or line.startswith(";;;"):
            continue
        head, _, phones = line.partition(" ")
        word = re.sub(r"\(\d+\)$", "", head).lower()
        if phones:
            variants.setdefault(word, []).append(phones.strip())
    return variants


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bank-dir", required=True)
    parser.add_argument("--name", default="bank")
    parser.add_argument("--out")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    bank_dir = (root / args.bank_dir).resolve()
    dictionary = json.loads((bank_dir / "dictionary.json").read_text())
    entries = json.loads((bank_dir / "entries.json").read_text())
    registry = json.loads((root / "sources/sources.json").read_text())
    registered = {source["id"] for source in registry["sources"]}
    cmu = load_cmu(root / "sources/cmudict/cmudict.dict")

    by_word = {entry["word"].lower(): entry for entry in entries}
    issues: list[dict[str, object]] = []
    flags: Counter[str] = Counter()

    def add(kind: str, word: str, detail: object) -> None:
        issues.append({"kind": kind, "word": word, "detail": detail})

    for word, outline in dictionary.items():
        entry = by_word.get(word.lower())
        if entry is None:
            add("missing_entry", word, outline)
            continue
        try:
            actual_sig = signature(outline)
        except ValueError:
            add("unparseable_outline", word, outline)
            continue
        if entry.get("signature") != actual_sig:
            add("signature_mismatch", word, [outline, entry.get("signature")])
        expected_changed = entry.get("signature") != entry.get("plainSignature")
        if bool(entry.get("changed")) != expected_changed:
            add("changed_mismatch", word, entry.get("changed"))
        if not entry.get("plainRule") or not entry.get("plainSignature"):
            add("missing_plain_rule", word, entry.get("outline"))
        phones = str(entry.get("cmudict", "")).strip()
        if phones and phones not in cmu.get(word.lower(), []):
            add("cmudict_mismatch", word, phones)
        source_ids = entry.get("sourceIds") or []
        unknown = [sid for sid in source_ids if sid not in registered]
        if unknown:
            add("unregistered_source", word, unknown)
        if not source_ids:
            add("no_sources", word, entry.get("outline"))
        if entry.get("brief") and not source_ids:
            add("brief_without_source", word, entry.get("outline"))
        if "steno-start-word-list" in source_ids:
            flags["word_list_overcitation"] += 1
        if entry.get("collisionResolved") and not entry.get("brief"):
            flags["collision_resolved_rule"] += 1
        if "*" in outline and not entry.get("brief") and entry.get("collisionResolved"):
            flags["star_collision_rule"] += 1
        rule = str(entry.get("rule", ""))
        m = re.search(r"coda ([^.]+)\.", rule)
        if m:
            coda = m.group(1).strip()
            if coda not in ("none", "?"):
                phones_in_coda = [p for p in coda.split() if p]
                if len(phones_in_coda) > 1:
                    flags["multi_phone_coda"] += 1
        if word.lower().endswith("le") and re.search(r"(?i)[tl]$", rule):
            flags["le_elision_candidate"] += 1

    result = {
        "name": args.name,
        "bank_dir": str(bank_dir.relative_to(root)),
        "words": len(dictionary),
        "entries": len(entries),
        "issues": issues,
        "issue_counts": dict(Counter(issue["kind"] for issue in issues)),
        "flags": dict(flags),
        "source_id_counts": dict(
            Counter(sid for entry in entries for sid in entry.get("sourceIds", []))
        ),
    }
    print(json.dumps(result, indent=2))
    if args.out:
        (root / args.out).write_text(json.dumps(result, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
