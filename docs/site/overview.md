# Overview

Sigil Bitcoin is a workspace of Bitcoin libraries for Sigil.

The packages are layered so applications can import only the pieces they need:

- `(sigil bitcoin primitives)` provides HASH160, HASH256, tagged hashes, and Taproot tag constants.
- `(sigil bitcoin encoding)` provides hex, Base58Check, Bech32, Bech32m, and SegWit address codecs.
- `(sigil secp256k1)` provides native libsecp256k1 bytevector bindings, including public-key point operations and x-only Taproot key tweaks.
- `(sigil bitcoin keys)` provides WIF, addresses, BIP32 extended keys, and BIP39 mnemonics.
- `(sigil bitcoin script)` provides script byte constructors and standard scriptPubKey templates.
- `(sigil bitcoin tx)` provides transaction structs, wire serialization, txids, P2PKH/P2WPKH/P2WSH single-key/P2TR signing, and PSBT v0 parsing, metadata preservation, input/output annotation, signing, and finalization helpers.
- `(sigil bitcoin miniscript)` provides Miniscript fragments, type metadata, hash-lock and branch combinators, descriptor parsing with checksums, BIP389 multipath key derivation, Taproot script-tree hashing and output-key compilation, `multi_a` Tapscript compilation, concrete BIP327 `musig(...)` key aggregation for Taproot descriptor scriptPubKeys, BIP388 wallet policy expansion, PSBT planning records with WSH and single-leaf Taproot script material, and descriptor-plan PSBT signing wrappers.
- `(sigil bitcoin consensus)` provides block/header records, wire parsing and serialization, Merkle roots, compact target decoding, proof-of-work checks, header-chain linkage, chain work, retarget validation, subsidy checks, activation-height gates, and UTXO-backed block connection with standard P2PKH/P2SH/P2WPKH/P2WSH/P2TR signature checks.
- `(sigil bitcoin p2p)` provides Bitcoin network envelopes, checksums, `version`/`verack`, `ping`/`pong`, `getheaders`, `headers`, relay payload codecs, socket envelope I/O, peer-session orchestration, header-sync loops, peer selection, and relay scheduling.
- `(sigil bitcoin node)` provides chain configs, SQLite-backed header/block storage, best-header/status queries, validated header ingestion, peer-driven sync, bounded live probes, and long-running node loop scaffolding.

The generated API reference is built from the same JSON files produced by `sigil build`.
