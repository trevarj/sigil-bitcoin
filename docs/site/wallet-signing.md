# Wallet Signing Capability Map

The current stack can already build a simple SegWit v0 wallet flow.

- Generate or import BIP39 mnemonic entropy with `(sigil bitcoin keys)`.
- Derive BIP32 private and public keys, including BIP44/49/84/86 account and address keys.
- Convert public keys into P2WPKH addresses.
- Construct unsigned transactions with `(sigil bitcoin tx)`.
- Create a PSBT from the unsigned transaction.
- Attach witness UTXO data and sign P2WPKH inputs.
- Compute BIP341 key-path sighashes for Taproot spends.
- Finalize P2WPKH inputs and extract the signed transaction.

The first complete signing path is P2WPKH with `SIGHASH_ALL`.

Still pending:

- P2PKH signing.
- Taproot key-path signing.
- PSBT BIP32 derivation records and Taproot fields.
- Descriptor-driven change detection and input ownership.
