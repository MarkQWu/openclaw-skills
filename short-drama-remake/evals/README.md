# short-drama-remake evals

This directory documents smoke tests for the public skill package. Do not place
real scripts, user source material, generated ingest output, or Downloads files
here.

## Smoke Tests

1. Run `python3 scripts/split_short_drama_source.py --self-test`.
2. Verify partial input is labeled as a sample/opening skeleton and does not make full-series claims.
3. Verify complete input still requires progressive reading before full-series skeleton claims.
4. Verify PDF duplicate heading-run warnings remain documented in `references/ingest-and-file-management.md`.
