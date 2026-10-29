# Provenance

Planned files:

- `sources.json`: source registry with licences, URLs and hashes.
- `entries.json`: one record per word and outline, pointing to source ids.
- `build.json`: generator commit, command, input hashes, output hashes and date.

A build fails if an entry has no source.
