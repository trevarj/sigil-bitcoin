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
- Attach non-witness UTXO data for P2PKH inputs.
- Attach witness UTXO data for SegWit v0 and Taproot key-path inputs.
- Preserve global, input, and output unknown/proprietary PSBT keys during parse and serialize.
- Preserve input BIP32 and Taproot derivation records for wallet coordination.
- Sign and finalize P2PKH, P2WPKH, and BIP86-style Taproot key-path PSBT inputs.
- Compute BIP341 key-path sighashes for Taproot spends.
- Extract finalized PSBTs into signed transactions.

The complete PSBT signing/finalization paths are P2PKH, P2WPKH with `SIGHASH_ALL`, and BIP86-style Taproot key-path spends with `SIGHASH_DEFAULT` or `SIGHASH_ALL`.

Still pending:

- Descriptor-driven change detection and input ownership.
- Output-side PSBT derivation records for descriptor-derived change outputs.
