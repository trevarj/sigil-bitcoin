# Bitcoin Implementation Checklist

Use this before implementing or reviewing Bitcoin behavior changes.

## References

- [ ] Read each relevant BIP end to end.
- [ ] Note the exact BIP numbers and sections in the final handoff.
- [ ] Check public APIs and behavior from rust-bitcoin, rust-secp256k1,
  rust-miniscript, or other directly relevant rust-bitcoin-family crates.
- [ ] Check Bitcoin Core behavior or vectors when consensus, policy, script,
  descriptor, or PSBT semantics are involved.

## Design

- [ ] Keep public API names and data shapes close to established rust-bitcoin
  conventions unless Sigil style requires a clearer fit.
- [ ] Preserve unknown, proprietary, or future extension fields where the
  relevant BIP requires round-trip behavior.
- [ ] Reject malformed inputs explicitly with focused invalid-input tests.
- [ ] Avoid consensus-affecting shortcuts or ambiguous coercions.

## Tests

- [ ] Add or update BIP, Bitcoin Core, rust-bitcoin, or rust-miniscript vectors
  under `tests/vectors/` when practical.
- [ ] Cover serialization and parsing round trips.
- [ ] Cover valid examples, boundary values, malformed encodings, and type
  errors.
- [ ] Run the relevant package harness and `./scripts/test-all.sh` for changes
  that cross package boundaries.

## Handoff

- [ ] List the BIPs/specs read.
- [ ] List external APIs consulted.
- [ ] List vector files added or changed.
- [ ] List checks run and their results.
