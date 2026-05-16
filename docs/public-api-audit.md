# Public API Audit

Audit opened: 2026-05-16

Goal: re-evaluate every public package API for a small, ergonomic surface that
balances functionality, correctness, and ease of use.

## Standards

- Every exported function has a `;;;` doc comment with example usage.
- Generated accessors and predicates may inherit examples from constructor or
  workflow docs when separate examples would be repetitive.
- Public names, argument order, return values, and error behavior should be
  idiomatic for Sigil while taking inspiration from rust-bitcoin-family APIs.
- Facade modules should expose common workflows. Low-level submodules should
  remain available only when they serve explicit advanced use cases.
- Avoid duplicate exports, convenience aliases without clear value, and internal
  helpers leaking across package boundaries.

## Package Review Tasks

- [ ] `sigil-secp256k1`: review scalar/public-key/x-only/Schnorr/ECDSA exports
  for naming consistency, error behavior, and example coverage.
- [ ] `sigil-bitcoin-primitives`: review hash/tag exports and constants for
  minimality and example coverage.
- [ ] `sigil-bitcoin-encoding`: review hex, Base58Check, Bech32, Bech32m, and
  SegWit address exports for cohesive names, validation behavior, and examples.
- [ ] `sigil-bitcoin-keys`: review WIF, address, BIP32, and BIP39 exports for
  workflow-oriented facades, return shapes, and examples.
- [ ] `sigil-bitcoin-script`: review script constructors and standard templates
  for consistent bytevector behavior and examples.
- [ ] `sigil-bitcoin-tx`: review transaction types, wire codecs, sighash,
  signing helpers, and facade exports for boundary clarity and examples.
- [ ] `sigil-bitcoin-psbt`: review PSBT base, wire, annotation, signing, and
  finalization exports for workflow cohesion, unknown-field preservation, and
  examples.
- [ ] `sigil-bitcoin-miniscript`: review Miniscript, descriptor, wallet-policy,
  MuSig, derivation, planning, and PSBT integration exports for a balanced
  facade/submodule split and examples.
- [ ] `sigil-bitcoin-demo`: review whether browser demo exports should remain
  public package API or be treated as toolbench internals.

## Verification Tasks

- [ ] Add or update API docs/examples for every reviewed export.
- [ ] Add tests for public examples where practical.
- [ ] Regenerate docs with `./scripts/docs-build.sh`.
- [ ] Run package harnesses affected by API changes.
- [ ] Run `./scripts/test-all.sh` after cross-package API changes.
