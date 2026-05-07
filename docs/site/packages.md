# Package Guide

Use this page as a quick map from package to responsibility.

## Primitives

`(sigil bitcoin primitives)` contains hash combinators used across the workspace.

## Encoding

`(sigil bitcoin encoding)` contains user-facing codecs for hex, Base58Check, Bech32, Bech32m, and SegWit addresses.

## secp256k1

`(sigil secp256k1)` is the native libsecp256k1 binding. Higher layers use it for ECDSA, Schnorr, public key derivation, scalar tweaks, x-only keys, and Taproot key tweaks.

## Keys

`(sigil bitcoin keys)` builds wallet-level key and address functionality on top of secp256k1, encoding, and hash primitives.

## Script

`(sigil bitcoin script)` constructs raw script bytevectors for standard output types and Miniscript compilation.

## Transactions and PSBT

`(sigil bitcoin tx)` owns transaction records, serialization, parsing, txids, sighashes, P2PKH/P2WPKH/P2TR key-path signing, and PSBT v0 operations including non-witness UTXOs, derivation records, unknown/proprietary keys, and Taproot key signatures.

## Miniscript

`(sigil bitcoin miniscript)` owns policy fragments, hash-lock and branch combinator compilation, descriptors, script compilation, and BIP388 wallet policy expansion.
