# Wallet Signing Capability Map

The current stack can build simple legacy, SegWit v0, and Taproot key-path signing flows.

- Generate or import BIP39 mnemonic entropy with `(sigil bitcoin keys)`.
- Derive BIP32 private and public keys, including BIP44/49/84/86 account and address keys.
- Convert public keys into P2PKH, P2WPKH, or P2TR addresses.
- Construct unsigned transactions with `(sigil bitcoin tx)`.
- Sign legacy P2PKH inputs with `transaction-sign-p2pkh-input`.
- Sign SegWit v0 P2WPKH inputs with `transaction-sign-p2wpkh-input`.
- Sign BIP86-style Taproot key-path inputs with `transaction-sign-p2tr-keypath-input`.
- Create a PSBT from the unsigned transaction.
- Attach witness UTXO data and sign P2WPKH inputs.
- Compute BIP341 key-path sighashes for Taproot spends.
- Finalize P2WPKH inputs and extract the signed transaction.

The complete PSBT signing/finalization path is currently P2WPKH with `SIGHASH_ALL`.

Still pending:

- PSBT finalization paths for P2PKH and Taproot key-path inputs.
- PSBT BIP32 derivation records and Taproot fields.
- Descriptor-driven change detection and input ownership.
