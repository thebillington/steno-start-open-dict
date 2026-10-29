# Sources and provenance

The source registry is `sources/sources.json`.

External source files are **not committed** to this repository. The repository
contains only:

- source URLs and pinned revisions or archive timestamps;
- licences and attribution;
- SHA-256 hashes and byte counts;
- the fetch and verify script;
- the generated dictionary, provenance and validation report.

## Fetching

```sh
python3 scripts/fetch_sources.py
```

The script writes the external files into `sources/cache/`, which is ignored by
git, and verifies every file against the pinned SHA-256. It will reuse a
verified cache and will fail if a downloaded file does not match.

## Pinned sources

- CMUdict at commit `74790861f652b15e4ac49015a90074ad62a27690`, BSD-2-Clause.
- Wikipedia: Stenotype at revision `1378936604`, CC BY-SA 4.0.
- Plover Wiki Top 100, Brief Ideas, Cheat Sheets and Plover theory at their
  pinned oldids, CC BY as stated in the wiki footer.
- Art of Chording Wayback snapshots listed in
  `sources/art-of-chording/web-archive/pages.json`, CC BY-SA 4.0 per the archived
  website footer. The CDX capture list is `wayback-cdx.json`.
- Steno Start authored 500-word list, CC BY-SA 4.0.

## Excluded

- Plover main.json and derivatives.
- Typey Type and other GPL dictionaries.
- Lapwing until its licence is clarified.
- StenEd, Magnum, Phoenix and other proprietary dictionaries.
- Any source without a licence and hash.

The Plover Wiki is a public theory reference, not the GPL dictionary file. The
pages used are pinned by oldid and hash.
