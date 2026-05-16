# Test Vectors

Durable Bitcoin test vectors live here. Package tests may still keep small
inline fixtures when that is clearer, but substantial BIP, Bitcoin Core,
rust-bitcoin, and rust-miniscript vectors should be mirrored here so future
agents can audit coverage without scraping test source.

Current seed files:

- `hash-vectors.json` — HASH160, HASH256, and tagged-hash known-answer vectors.
- `encoding-vectors.json` — Base58, Base58Check, Bech32, Bech32m, and SegWit
  address vector sources used by `(sigil bitcoin encoding)`.
- `transaction-vectors.json` — Bitcoin Core raw transaction fixtures mirrored
  from transaction round-trip tests.

When adding Bitcoin functionality:

- Include the source specification or upstream fixture name.
- Preserve exact hex/text values.
- Keep invalid vectors near valid vectors for the same format.
- Reference the vector file from the package test that consumes or mirrors it.
