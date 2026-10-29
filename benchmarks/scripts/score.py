#!/usr/bin/env python3
"""Compare a generated word bank with an external reference dictionary.

Examples:
  python3 benchmarks/scripts/score.py \
    --generated app/assets/word_banks.json \
    --bank benchmarks/wordlists/everyday-500.txt \
    --reference benchmarks/references/plover.json \
    --reference-format stroke2word
"""
import argparse, json, statistics, sys
from pathlib import Path

KEYS = list('STKPWHRAO*EUFRPBLGTSDZ')
RIGHT_START = 12

def parse(stroke):
    i = 0; ids = []
    for ch in stroke.strip().upper():
        if ch == '-':
            i = max(i, RIGHT_START); continue
        while i < len(KEYS) and KEYS[i] != ch: i += 1
        if i >= len(KEYS): raise ValueError(stroke)
        ids.append(i); i += 1
    return tuple(sorted(set(ids)))

def sig(stroke): return '|'.join(map(str, parse(stroke)))
def norm(stroke): return stroke.replace('-', '')
def groups(ids):
    return (set(k for k in ids if k < 7),
            set(k for k in ids if k in (7, 8, 10, 11)),
            set(k for k in ids if k == 9),
            set(k for k in ids if k >= 12))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--generated', required=True, help='word -> stroke JSON')
    ap.add_argument('--bank', required=True, help='one word per line')
    ap.add_argument('--reference', required=True, help='external reference JSON')
    ap.add_argument('--reference-format', choices=['stroke2word', 'word2stroke'], default='stroke2word')
    ap.add_argument('--out', help='optional results JSON')
    args = ap.parse_args()

    generated = {
        str(k).strip().lower(): str(v).strip()
        for k, v in json.loads(Path(args.generated).read_text()).items()
    }
    words = [l.strip().lower() for l in Path(args.bank).read_text().splitlines() if l.strip()]
    raw = json.loads(Path(args.reference).read_text())
    ref = {}
    for k, v in raw.items():
        if args.reference_format == 'stroke2word':
            ref[str(v).strip().lower()] = str(k).strip()
        else:
            ref[str(k).strip().lower()] = str(v).strip()

    exact = compared = 0; jaccard = []; cat = {}
    for w in words:
        g = generated.get(w)
        e = ref.get(w)
        if g is None or e is None: continue
        compared += 1
        ge, ee = set(parse(g)), set(parse(e))
        if sig(g) == sig(e): exact += 1
        jaccard.append(len(ge & ee) / len(ge | ee) if ge | ee else 1)
        if sig(g) != sig(e):
            a, b, c, d = groups(ge); e1, e2, e3, e4 = groups(ee)
            bits = []
            if a != e1: bits.append('onset')
            if b != e2: bits.append('vowel')
            if c != e3: bits.append('star')
            if d != e4: bits.append('coda')
            key = '+'.join(bits) or 'other'
            cat[key] = cat.get(key, 0) + 1

    result = {
        'bank_words': len(words),
        'generated_coverage': sum(1 for w in words if w in generated) / len(words) if words else 0,
        'reference_coverage': sum(1 for w in words if w in ref) / len(words) if words else 0,
        'compared': compared,
        'exact': exact,
        'exact_percent': round(100 * exact / compared, 1) if compared else 0,
        'mean_jaccard': round(statistics.mean(jaccard), 3) if jaccard else 0,
        'categories': cat,
    }
    print(json.dumps(result, indent=2))
    if args.out: Path(args.out).write_text(json.dumps(result, indent=2) + '\n')

if __name__ == '__main__':
    main()
