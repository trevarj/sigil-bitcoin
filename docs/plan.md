# Sigil Bitcoin Libraries — Implementation Plan

Goal: build a rust-bitcoin-like ecosystem in Sigil. LLM-driven development,
using upstream `sigil-crypto` primitives where available.

## Architecture

```
Layer 0 — Primitives
├── bignums (mbedTLS mpi exposure through sigil-crypto)
├── secp256k1 (native package linked to libsecp256k1)
├── RIPEMD-160, HMAC-SHA512 (native sigil-crypto bindings)
└── HASH160, HASH256, tagged hashes (pure Sigil combinators)

Layer 1 — Encoding (pure Sigil, sigil-bitcoin-encoding)
├── Hex, Base58check, Bech32/Bech32m

Layer 2 — Keys & Addresses (sigil-bitcoin-keys)
├── Private keys (WIF)
├── Public keys (compressed/uncompressed)
├── Address derivation (P2PKH, P2SH, P2WPKH, P2WSH, P2TR)
├── BIP32 HD key derivation
└── BIP39 mnemonics

Layer 3 — Transactions (sigil-bitcoin-tx)
├── TxIn, TxOut, Transaction structs
├── Legacy + SegWit (v0) + Taproot (v1) serialization
├── PSBT (BIP 174)
├── Signing (ECDSA + Schnorr)
└── Sighash computation (legacy + BIP 143 + BIP 341)

Layer 4 — Script (sigil-bitcoin-script, sigil-bitcoin-miniscript)
├── Script evaluation engine
├── Standard scripts (P2PKH, P2SH, P2WSH, P2TR)
├── Miniscript parser, type checker, and script compiler
└── Output descriptors

Layer 5 — Blocks & Consensus (sigil-bitcoin-consensus)
├── Block header parsing
├── Merkle tree construction
└── Proof-of-work validation

Layer 6 — Networking (sigil-bitcoin-p2p)
├── P2P message serialization
├── Handshake, version negotiation
└── Block/tx relay
```

## Priority Order (user-ranked)

1. Keys & wallets (WIF, BIP32, BIP39, PSBT)
2. Transactions & signing (ECDSA, Schnorr, sighash)
3. Encoding/addresses (base58check, bech32/bech32m)
4. Script engine (Miniscript, descriptors)
5. Blocks & consensus
6. Networking/P2P

## Critical Infrastructure Blockers

| Gap | Solution | Effort |
|-----|----------|--------|
| secp256k1 curve | Native package linked to libsecp256k1 0.7.1 (available in Guix) | Done |
| Big integers (bignums) | Exposed through upstream `sigil-crypto` mpi bindings | Done |
| RIPEMD-160 | Exposed through upstream `sigil-crypto` native binding | Done |
| HMAC-SHA512 | Exposed through upstream `sigil-crypto` native binding | Done |

## What Already Works in Pure Sigil Today

- SHA-256d (two `sha256-bytes` calls)
- RIPEMD-160 via upstream `sigil-crypto`
- Hex encoding (trivial byte-to-hex)
- VarInt (switch on u8 prefix)
- Bech32/Bech32m (polynomial-over-GF32, no bigints needed)
- Transaction serialization (`(sigil io)` bytevector ports)
- Base64/Base64url (in sigil-crypto)

## Current Status

- Phase 0 is complete.
- Current verification is consolidated in `./scripts/test-all.sh`, which runs
  root workspace tests, native secp256k1-dependent package harnesses, and wasm
  validation.
- Standards counters are available through `./scripts/standards-check.sh`.
- Durable vector mirrors live under `tests/vectors/`; package tests may still
  keep small inline fixtures when that is clearer.
- `sigil-bitcoin-primitives` passes HASH160, HASH256, and BIP-340 tagged-hash vectors.
- `sigil-bitcoin-encoding` passes hex, Base58, Base58Check, full BIP173/BIP350 Bech32/Bech32m checksum vectors, SegWit v0, and SegWit v1 vectors.
- `sigil-secp256k1` now uses a native C module linked against `libsecp256k1` instead of runtime `(sigil ffi)` dynamic loading.
- `sigil-secp256k1` package harness tests pass all ECDSA, DER, tweak, keypair, x-only tweak, Schnorr, public-key point operation, and invalid-input assertions.
- `sigil-secp256k1` x-only keypair helpers return serialized 32-byte x-only public keys, and public-key helpers expose x-only serialization, scalar multiplication, key combination, and Taproot x-only tweaks.
- `sigil-bitcoin-keys` provides network structs, WIF, public-key predicates, P2PKH/P2SH/P2WPKH/P2WSH/P2TR address helpers, BIP32 extended-key structs and derivation, BIP43/BIP44/BIP49/BIP84/BIP86 account helpers, and BIP39 English mnemonic helpers.
- `sigil-bitcoin-keys` package harness tests pass WIF, address, BIP32 vectors 1/2/3, invalid extended-key, public-derivation parity, account derivation helpers, and BIP39 128/160/192/224/256-bit entropy assertions.
- `sigil-bitcoin-script` provides script byte constructors, pushdata encoding, witness programs, and standard P2PKH/P2SH/P2WPKH/P2WSH/P2TR scriptPubKey templates.
- `sigil-bitcoin-tx` provides transaction structs, compactSize encoding/decoding, legacy/SegWit parsing and serialization, Bitcoin Core raw transaction round-trip coverage, txid/wtxid helpers, `SIGHASH_ALL` legacy/BIP143 hashes, BIP341 key-path and script-path sighashes, P2PKH/P2WPKH/P2WSH single-key/P2TR key-path signing, and PSBT v0 support for witness UTXOs, non-witness UTXOs, redeem/witness scripts, partial signatures, input/output BIP32/Taproot derivation records, unknown/proprietary key preservation, Taproot key and script signatures, Taproot leaf scripts, finalization, and extraction.
- `sigil-bitcoin-miniscript` provides fragment ASTs, parsing, canonical strings, type/signing metadata, hash-lock and boolean combinator script compilation, descriptor parsing/checksums, descriptor key derivation, descriptor scriptPubKey compilation including Taproot script-tree output keys, `multi_a`/`CHECKSIGADD` Tapscript compilation, descriptor and wallet-policy PSBT planning records with WSH and single-leaf Taproot script material, descriptor-plan PSBT annotation and standard P2PKH/P2WPKH/P2TR key-path/script-path signing/finalization wrappers, concrete BIP327 `musig(...)` Taproot key aggregation, and BIP388 wallet policy descriptor expansion with BIP390 `musig(...)` placeholders.
- `sigil-bitcoin-consensus` provides block/header records, wire parsing and serialization, Merkle root construction, compact target decoding, proof-of-work checks, header-chain linkage, chain work, and retarget validation.
- `sigil-bitcoin-p2p` provides network envelopes, payload checksums, `version`/`verack`, `ping`/`pong`, `getheaders`, and `headers` payload codecs.
- `sigil-bitcoin` has a standalone documentation site generator that reads compiler JSON docs, emits a docs.rs-inspired static site to `public/`, and includes concise guide pages under `docs/site/`.
- `hash160` uses upstream `sigil-crypto`'s native `ripemd160` binding when it
  is linked in the current runtime, with a private compatibility fallback for
  direct test runners using stale bundled crypto natives.
- Root workspace tests pass under the direct runner. The secp and keys test files record skip markers there because multi-package workspace tests do not currently build a native harness.
- BIP39 seed derivation implements PBKDF2-HMAC-SHA512 in `sigil-bitcoin-keys`
  on top of upstream `sigil-crypto`'s `hmac-sha512-bytes`.
- The `sigil-secp256k1` package harness covers invalid input lengths, type errors, public-key parse failures, invalid DER, and invalid key material.

Known-good root verification command:

```sh
guix shell -m manifest.scm -- sigil test --redirects ./dev-redirects.sgl --no-color
```

Known-good secp256k1 harness verification command:

```sh
cd packages/sigil-secp256k1
guix shell -m ../../manifest.scm -- sigil test test/test-secp256k1.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

Known-good keys harness verification command:

```sh
cd packages/sigil-bitcoin-keys
guix shell -m ../../manifest.scm -- sigil test test/test-keys.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

Known-good miniscript harness verification command:

```sh
cd packages/sigil-bitcoin-miniscript
guix shell -m ../../manifest.scm -- sigil test test/test-miniscript.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

Known-good full local verification command:

```sh
./scripts/test-all.sh
```

## What Needs NO Compiler Changes

Every gap is solvable through extending sigil-crypto's C bindings, FFI to C libraries,
or pure Sigil code. No changes to the Sigil VM or compiler are required.

## Phases

### Phase 0: Dev Environment

- `manifest.scm` for Guix shell with sigil + libsecp256k1 + build tools
- Directory scaffolding for sigil-bitcoin monorepo

### Phase 1: Unblock Crypto Primitives

- RIPEMD-160, HMAC-SHA512, and mpi bindings are upstreamed in `sigil-crypto`.

### Phase 2: sigil-secp256k1 Native Bindings

- Native Sigil package linked to libsecp256k1
- Bytevector API with native C validation and serialization
- ECDSA sign/verify, Schnorr sign/verify, pubkey operations

### Phase 3: sigil-bitcoin Libraries

- 3a. sigil-bitcoin-primitives (HASH160, HASH256, tagged hashes)
- 3b. sigil-bitcoin-encoding (hex, base58check, bech32/bech32m)
- 3c. sigil-bitcoin-keys (WIF, BIP32, BIP39, addresses)
- 3d. sigil-bitcoin-tx (transaction, PSBT, signing, sighash)
- 3e. sigil-bitcoin-script (script engine, standard scripts)
- 3f. sigil-bitcoin-miniscript (Miniscript AST, parser, type checker, script compiler, descriptors)
- 3g. sigil-bitcoin-consensus (blocks, merkle, PoW)
- 3h. sigil-bitcoin-p2p (messages, handshake)

## Verification

- Test vectors from BIPs, Bitcoin Core, rust-bitcoin, and rust-miniscript live
  in `tests/vectors/` when practical, with focused inline fixtures allowed in
  package tests.
- `(sigil test)` drives assertions against known-answer vectors.
- Critical vectors: BIP32 (1,2,3), BIP39, sighash (legacy/143/341), bech32/bech32m

## Path to Upstream

1. Propose sigil-bitcoin as official project under sigil/ org
2. Submit individual packages incrementally (encoding first, then keys, then tx)

## Task Board

### Done

- [x] Scaffold `sigil-bitcoin-primitives`.
- [x] Scaffold `sigil-bitcoin-encoding`.
- [x] Add HASH160, HASH256, and BIP-340 tagged-hash tests.
- [x] Add hex, Base58, Base58Check, Bech32, Bech32m, and SegWit address tests.
- [x] Fix Bech32 charset length bug (`a7l`, not `a7wl`).
- [x] Add exact BIP173/BIP350 SegWit encode assertions.
- [x] Add private RIPEMD-160 compatibility fallback for direct runners whose bundled crypto native is stale.
- [x] Replace the HASH160 fallback with upstream `sigil-crypto` `ripemd160`.
- [x] Replace `sigil-secp256k1` dynamic FFI with a native C module.
- [x] Add native harness dependencies and redirects for `sigil-secp256k1`.
- [x] Gate secp256k1 tests under the direct workspace runner while keeping full assertions in the native harness.
- [x] Implement BIP39 PBKDF2-HMAC-SHA512 on top of upstream `hmac-sha512-bytes`.
- [x] Expand Bech32/Bech32m coverage with the full BIP173/BIP350 valid and invalid checksum vector sets.
- [x] Add `sigil-bitcoin-keys` with native-secp package harness.
- [x] Add network structs, WIF encode/decode, and public-key predicates.
- [x] Add P2PKH, P2SH, P2WPKH, P2WSH, and P2TR address helpers.
- [x] Add BIP32 extended-key structs, xprv/xpub encode/decode, and private/public child derivation.
- [x] Add generated BIP39 English wordlist data, entropy/mnemonic conversion, and seed derivation.
- [x] Expand `sigil-bitcoin-keys` with BIP32 vectors 2 and 3, invalid extended-key coverage, and public-derivation parity checks.
- [x] Add BIP39 vectors for 160/192/224/256-bit entropy and document the generated wordlist source.
- [x] Return serialized 32-byte x-only public keys from the secp256k1 keypair API.
- [x] Add `sigil-bitcoin-script` skeleton with pushdata encoding and standard scriptPubKey constructors.
- [x] Add `sigil-bitcoin-tx` skeleton with transaction structs, compactSize, and legacy/SegWit serialization tests.
- [x] Add outpoint, txin, txout, and transaction IDs using little-endian Bitcoin wire order.
- [x] Add transaction parsing for compactSize, outpoints, inputs, outputs, witness stacks, and full transactions.
- [x] Add `SIGHASH_ALL` helpers for legacy and BIP143 SegWit v0 transactions.
- [x] Add P2WPKH signing helper and native tx harness coverage.
- [x] Add PSBT global/input/output maps, serialization/parsing, witness UTXOs, partial signatures, P2WPKH finalization, and extraction.
- [x] Add `sigil-bitcoin-miniscript` with initial AST, parser, type checker, and script compiler coverage.
- [x] Correct `pk_k` semantics, add `pk`, `pk_h`, multisig, wrappers, threshold parsing, descriptors, and BIP388 wallet policy expansion.
- [x] Add a standalone `sigil-bitcoin` docs site generator, guide pages, local build/serve scripts, and generated API search index.

### Next

- [x] Investigate why `ripemd160` appears in `sigil-crypto` metadata but is unbound in the root direct test runtime.
- [x] Add a root-level helper script that runs direct workspace tests plus native package harnesses.
- [x] Replace absolute local Sigil redirects in `dev-redirects.sgl` with a portable workspace-local path when the Sigil checkout layout is finalized.
- [x] Add invalid-input coverage for `sigil-secp256k1` length/type checks and parse failures.
- [x] Add account-level helpers for common paths after deciding whether descriptors or PSBT should own derivation-path policy.
- [x] Add transaction serialization round-trip tests for Bitcoin Core/rawtx fixtures.
- [x] Add BIP341 Taproot sighash helpers.
- [x] Add P2PKH and P2TR key-path signing helpers.
- [x] Extend PSBT signing/finalization beyond P2WPKH to P2PKH and P2TR key-path inputs.
- [x] Add PSBT non-witness UTXO and Taproot key-signature fields.
- [x] Add PSBT BIP32 derivation records, Taproot derivation fields, and unknown/proprietary key preservation.
- [x] Add hash-lock fragments, `andor`, `or_b`, `or_c`, `or_i`, and executable `thresh` compilation using rust-miniscript/Bitcoin Core vectors.
- [x] Add Miniscript type metadata beyond the current coarse base type, including malleability and satisfaction properties needed for signing.
- [x] Add BIP389 multipath parsing and Taproot descriptor script-tree parsing.
- [x] Add descriptor checksums and parser-level BIP388/BIP390 `musig(...)` placeholders.
- [x] Implement BIP327 MuSig2 aggregate key derivation for concrete `musig(...)` Taproot descriptor scriptPubKeys.
- [x] Expand descriptor key derivation for ranged xpubs, multipath keys, and `musig(...)` participants before PSBT integration.
- [x] Add descriptor and wallet-policy PSBT planning records with derived scripts, key origins, and branch-based change flags.
- [x] Use descriptor PSBT plans to annotate PSBT inputs/outputs and select P2PKH/P2WPKH/P2TR signing/finalization helpers.
- [x] Add PSBT output BIP32/Taproot derivation fields for descriptor change-output tracking.
- [x] Add WSH redeem/witness script material to descriptor PSBT plans.
- [x] Add PSBT redeem/witness script fields and WSH signing/finalization helpers.
- [x] Compile Taproot descriptor script trees into Taproot output keys.
- [x] Add Taproot script-path PSBT fields, sighashes, and single-key checksig signing/finalization helpers.
- [x] Add Tapscript `multi_a`/`CHECKSIGADD` compilation and descriptor PSBT integration for multi-key Taproot script-path spends.
- [x] Replace the repo-local docs generator with Press.
- [x] Add `sigil-bitcoin-consensus` with block/header records, wire parsing, Merkle roots, compact target decoding, and proof-of-work checks.
- [x] Add `sigil-bitcoin-p2p` with network envelopes, checksums, handshake payloads, ping/pong, getheaders, and headers codecs.
- [x] Extend `sigil-bitcoin-consensus` with header-chain validation, difficulty adjustment windows, and chain-work accounting.
- [ ] Extend `sigil-bitcoin-consensus` with block subsidy/coinbase checks and UTXO-backed block connection.
- [ ] Extend `sigil-bitcoin-p2p` with socket transport, peer state, handshake orchestration, header-sync loops, and block/transaction relay messages.
