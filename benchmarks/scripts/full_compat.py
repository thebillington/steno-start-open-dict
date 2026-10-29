#!/usr/bin/env python3
"""Score every word in a generated bank against a full external dictionary."""
from __future__ import annotations
import argparse, json, re
from pathlib import Path

KEYS = list("STKPWHRAO*EUFRPBLGTSDZ")
RIGHT_START = 12

def parse_stroke(stroke: str) -> tuple[int, ...]:
    i = 0; ids: list[int] = []
    for ch in stroke.strip().upper():
        if ch == "-": i = max(i, RIGHT_START); continue
        while i < len(KEYS) and KEYS[i] != ch: i += 1
        if i >= len(KEYS): raise ValueError(stroke)
        ids.append(i); i += 1
    return tuple(sorted(set(ids)))

def signature(stroke: str) -> str: return "|".join(map(str, parse_stroke(stroke)))
def outline_signature(outline: str):
    try: return tuple(signature(part) for part in outline.split("/"))
    except ValueError: return None

def load_reference(path: Path):
    raw = json.loads(path.read_text()); ref = {}
    for strokes, word in raw.items():
        word = str(word).strip().lower()
        if not word or " " in word: continue
        if not re.fullmatch(r"[a-z][a-z'.-]*", word): continue
        sig = outline_signature(str(strokes))
        if sig is None: continue
        ref.setdefault(word, []).append((str(strokes), sig))
    return ref

def groups(ids):
    return (
        set(k for k in ids if k < 7),
        set(k for k in ids if k in (7, 8, 10, 11)),
        set(k for k in ids if k == 9),
        set(k for k in ids if k >= 12),
    )

def category(gen, ref):
    g = set(parse_stroke(gen)); r = set(parse_stroke(ref))
    og, vg, sg, cg = groups(g); orr, vr, sr, cr = groups(r)
    bits = []
    if og != orr: bits.append("onset")
    if vg != vr: bits.append("vowel")
    if sg != sr: bits.append("star")
    if cg != cr: bits.append("coda")
    return "+".join(bits) or "other"

def score_bank(bank, reference):
    exact = present = mismatch_single = multi_only = 0
    missing = []; mismatches = []; cats = {}
    for word, outline in bank.items():
        refs = reference.get(word.lower())
        if not refs: missing.append(word); continue
        present += 1
        gs = (signature(outline),)
        if any(sig == gs for _, sig in refs): exact += 1; continue
        singles = [(o, s) for o, s in refs if len(s) == 1]
        if singles:
            mismatch_single += 1
            # choose the single-stroke reference with the smallest key-set distance
            gset = set(parse_stroke(outline))
            ref_outline, _ = min(singles, key=lambda x: len(gset ^ set(parse_stroke(x[0]))))
            cat = category(outline, ref_outline)
            cats[cat] = cats.get(cat, 0) + 1
            mismatches.append({"word": word, "generated": outline, "reference": ref_outline, "category": cat})
        else:
            multi_only += 1
            mismatches.append({"word": word, "generated": outline, "reference": refs[0][0], "category": "multi-only"})
    words = len(bank)
    return {
        "words": words, "present": present, "missing": len(missing), "missing_words": missing[:50],
        "exact": exact,
        "exact_percent_all": round(100 * exact / words, 1) if words else 0.0,
        "exact_percent_present": round(100 * exact / present, 1) if present else 0.0,
        "mismatch_single": mismatch_single, "multi_only": multi_only,
        "categories": dict(sorted(cats.items(), key=lambda kv: -kv[1])),
        "mismatch_sample": mismatches[:60],
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--reference", required=True); ap.add_argument("--bank", required=True)
    ap.add_argument("--name", default="bank"); ap.add_argument("--out")
    args = ap.parse_args()
    ref = load_reference(Path(args.reference))
    bank = {str(k).strip().lower(): str(v).strip() for k, v in json.loads(Path(args.bank).read_text()).items()}
    result = {"name": args.name, **score_bank(bank, ref)}
    print(json.dumps(result, indent=2))
    if args.out: Path(args.out).write_text(json.dumps(result, indent=2) + "\n")
if __name__ == "__main__": main()
