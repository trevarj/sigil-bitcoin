# Sigil Bitcoin Libraries — Implementation Plan

Goal: build a rust-bitcoin-like ecosystem in Sigil. LLM-driven development, targeting
upstream contribution to sigil/sigil-crypto for missing primitives.

## Architecture

```
Layer 0 — Primitives (extend sigil-crypto)
├── bignums (mbedTLS mpi exposure)
├── secp256k1 (FFI to libsecp256k1)
├── RIPEMD-160, HMAC-SHA512 (extend crypto.c)
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

Layer 4 — Script (sigil-bitcoin-script)
├── Script evaluation engine
├── Standard scripts (P2PKH, P2SH, P2WSH, P2TR)
├── Miniscript
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
| secp256k1 curve | FFI to libsecp256k1 0.7.1 (available in Guix) | Medium |
| Big integers (bignums) | Expose mbedTLS mpi in sigil-crypto (already compiled, unreachable) | Medium |
| RIPEMD-160 | Add `MBEDTLS_RIPEMD160_C` to mbedTLS config + native binding | Low |
| HMAC-SHA512 | Add native binding to sigil-crypto (~15 lines C) | Trivial |

## What Already Works in Pure Sigil Today

- SHA-256d (two `sha256-bytes` calls)
- Hex encoding (trivial byte-to-hex)
- VarInt (switch on u8 prefix)
- Bech32/Bech32m (polynomial-over-GF32, no bigints needed)
- Transaction serialization (`(sigil io)` bytevector ports)
- Base64/Base64url (in sigil-crypto)

## What Needs NO Compiler Changes

Every gap is solvable through extending sigil-crypto's C bindings, FFI to C libraries,
or pure Sigil code. No changes to the Sigil VM or compiler are required.

## Phases

### Phase 0: Dev Environment

- `manifest.scm` for Guix shell with sigil + libsecp256k1 + build tools
- Directory scaffolding for sigil-bitcoin monorepo

### Phase 1: Unblock Crypto Primitives (PR to sigil/sigil-crypto)

- 1a. RIPEMD-160: add to mbedTLS config + expose in crypto.c
- 1b. HMAC-SHA512: native binding in crypto.c
- 1c. Bignums: expose mbedTLS mpi (add, sub, mul, div, mod, inv, cmp, shift)

### Phase 2: sigil-secp256k1 FFI Bindings

- Pure Sigil package using (sigil ffi) to libsecp256k1.so
- Zero-copy via bytevector->pointer
- ECDSA sign/verify, Schnorr sign/verify, pubkey operations

### Phase 3: sigil-bitcoin Libraries

- 3a. sigil-bitcoin-primitives (HASH160, HASH256, tagged hashes)
- 3b. sigil-bitcoin-encoding (hex, base58check, bech32/bech32m)
- 3c. sigil-bitcoin-keys (WIF, BIP32, BIP39, addresses)
- 3d. sigil-bitcoin-tx (transaction, PSBT, signing, sighash)
- 3e. sigil-bitcoin-script (script engine, standard scripts)
- 3f. sigil-bitcoin-consensus (blocks, merkle, PoW)
- 3g. sigil-bitcoin-p2p (messages, handshake)

## Verification

- Test vectors from BIPs as JSON files in tests/vectors/
- (sigil test) runner driving assertions against known-answer vectors
- Critical vectors: BIP32 (1,2,3), BIP39, sighash (legacy/143/341), bech32/bech32m

## Path to Upstream

1. PR to sigil/sigil-crypto with RIPEMD-160 + HMAC-SHA512 + mpi exposure
2. Propose sigil-bitcoin as official project under sigil/ org
3. Submit individual packages incrementally (encoding first, then keys, then tx)
