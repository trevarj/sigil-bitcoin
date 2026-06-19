# Package Guide

Use this page as a quick map from package to responsibility.

## Primitives

`(sigil bitcoin primitives)` contains hash combinators used across the workspace.

## Encoding

`(sigil bitcoin encoding)` contains user-facing codecs for hex, Base58Check, Bech32, Bech32m, and SegWit addresses.

## secp256k1

`(sigil secp256k1)` is the native libsecp256k1 binding. Higher layers use it for ECDSA, Schnorr, public key derivation, scalar tweaks, public-key point operations, x-only keys, and Taproot key tweaks.

## Keys

`(sigil bitcoin keys)` builds wallet-level key and address functionality on top of secp256k1, encoding, and hash primitives.

## Script

`(sigil bitcoin script)` constructs raw script bytevectors for standard output types and Miniscript compilation.

## Transactions and PSBT

`(sigil bitcoin tx)` owns transaction records, serialization, parsing, txids, sighashes, P2PKH/P2WPKH/P2WSH single-key/P2TR key-path signing, and PSBT v0 operations including non-witness UTXOs, redeem/witness scripts, input/output derivation records, annotation helpers, unknown/proprietary keys, and Taproot key signatures.

## Miniscript

`(sigil bitcoin miniscript)` owns policy fragments, type/signing metadata, hash-lock and branch combinator compilation, descriptors with checksums, BIP389 multipath key derivation, Taproot script-tree hashing and output-key compilation, `multi_a` Tapscript compilation, concrete BIP327 `musig(...)` key aggregation for Taproot descriptor scriptPubKeys, script compilation, BIP388 wallet policy expansion, PSBT planning records with WSH and single-leaf Taproot script material, and descriptor-plan PSBT signing wrappers.

## Consensus

`(sigil bitcoin consensus)` owns block/header records, wire parsing and serialization, Merkle root construction, compact target decoding, proof-of-work checks, header-chain linkage, chain work, retarget validation, subsidy checks, coinbase maturity, and UTXO-backed block connection.

## P2P

`(sigil bitcoin p2p)` owns Bitcoin network envelopes, payload checksums, handshake payloads, ping/pong nonces, header-sync message codecs, inventory/getdata/notfound relay payloads, tx/block payloads, and peer-state transitions.
