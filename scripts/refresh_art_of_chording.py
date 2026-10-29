#!/usr/bin/env python3
"""Refresh the pinned Art of Chording Wayback captures and their hashes.

This deliberately reads the archived URLs in pages.json. It writes the raw HTML
capture and a main-content text extraction next to it, then updates the
page-level hashes and the source-registry manifest hash.

Run from the lab root. Network access is only used by this maintenance script;
the dictionary build itself never uses the network.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
import time
import urllib.request
from pathlib import Path

from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "sources/art-of-chording/web-archive"
PAGES = ARCHIVE / "pages.json"
REGISTRY = ROOT / "sources/sources.json"

# The duplicate no-extension page and the .html page have the same article.
# Keep the path cited by the generator and drop the duplicate.
DUPLICATES = {"introduction/how-steno-works.html"}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def html_name(path: str) -> str:
    return path.replace("/", "_") + ".html"


def text_name(path: str) -> str:
    return path.replace("/", "_") + ".txt"


def fetch(url: str) -> bytes:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "steno-start-provenance-refresh/1.0",
            "Accept-Encoding": "gzip, deflate",
        },
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                data = response.read()
                if response.headers.get("Content-Encoding") == "gzip":
                    import gzip

                    data = gzip.decompress(data)
                if b"Your request has been blocked" in data:
                    raise RuntimeError("Wayback returned an abuse-block page")
                return data
        except Exception:
            if attempt == 3:
                raise
            time.sleep(1.5 * (attempt + 1))
    raise AssertionError("unreachable")


def extract_text(html: bytes) -> str:
    soup = BeautifulSoup(html, "lxml")
    main = soup.select_one(".theme-default-content") or soup.body
    if main is None:
        raise RuntimeError("capture has no body")
    return " ".join(main.get_text(" ", strip=True).split()) + "\n"


def main() -> int:
    manifest = json.loads(PAGES.read_text())
    kept = []
    for page in manifest["pages"]:
        path = page["path"]
        if path in DUPLICATES:
            old_html = ARCHIVE / html_name(path)
            old_text = ARCHIVE / text_name(path)
            old_html.unlink(missing_ok=True)
            old_text.unlink(missing_ok=True)
            continue
        print(f"fetch {path}", flush=True)
        html = fetch(page["archiveUrl"])
        text = extract_text(html)
        (ARCHIVE / html_name(path)).write_bytes(html)
        (ARCHIVE / text_name(path)).write_text(text)
        page["html"] = f"sources/art-of-chording/web-archive/{html_name(path)}"
        page["text"] = f"sources/art-of-chording/web-archive/{text_name(path)}"
        page["sha256"] = sha(html)
        page["textSha256"] = sha(text.encode())
        kept.append(page)
        time.sleep(0.4)
    manifest["pages"] = kept
    manifest["retrieved"] = "2026-10-29"
    PAGES.write_text(json.dumps(manifest, indent=2) + "\n")

    registry = json.loads(REGISTRY.read_text())
    manifest_hash = sha(PAGES.read_bytes())
    for source in registry["sources"]:
        if source["id"] != "art-of-chording-website":
            continue
        source["sha256"] = manifest_hash
        source["manifestSha256"] = manifest_hash
        source["bytes"] = PAGES.stat().st_size
        source["files"] = [
            "sources/art-of-chording/wayback-cdx.json",
            "sources/art-of-chording/wayback-evidence.json",
            "sources/art-of-chording/web-archive/LICENSE-EVIDENCE.md",
        ] + sorted(
            {
                page["html"]
                for page in kept
            }
            | {page["text"] for page in kept}
        )
    REGISTRY.write_text(json.dumps(registry, indent=2) + "\n")

    evidence = ARCHIVE.parent / "wayback-evidence.json"
    record = json.loads(evidence.read_text())
    record["note"] = (
        "Wayback raw captures re-fetched from the archive URLs in pages.json on "
        "2026-10-29. Every page has a SHA-256 for the HTML and the extracted "
        "main-content text. Abuse-block captures are rejected by the refresh "
        "script. The CDX snapshot list is retained as archive evidence."
    )
    record["retrieved"] = "2026-10-29"
    evidence.write_text(json.dumps(record, indent=2) + "\n")
    print(f"refreshed {len(kept)} pages, manifest {manifest_hash}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
