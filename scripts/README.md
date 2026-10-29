# Scripts

## Fetch external sources

```sh
python3 scripts/fetch_sources.py
```

Downloads the pinned CMUdict, Wikipedia, Plover Wiki and Wayback Art of Chording
files into `sources/cache/`, then verifies every SHA-256 against
`sources/sources.json` and the Art of Chording page manifest.

The cache is ignored by git. The public repository contains only metadata,
hashes and generated outputs.

Expected later scripts:

- build the dictionary;
- regenerate provenance;
- run the generator tests;
- run the licence and source checks;
- export the app asset.
