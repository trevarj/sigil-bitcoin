# Wallet Signing Capability Map

The current stack can build legacy, SegWit v0, and Taproot key-path or single-leaf script-path signing flows.

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
- Preserve input and output BIP32/Taproot derivation records for wallet coordination.
- Derive descriptor and wallet-policy PSBT plans for input/output annotation.
- Sign and finalize P2PKH, P2WPKH, single-key P2WSH, BIP86-style Taproot key-path, and single-leaf Taproot script-path PSBT inputs.
- Compile Taproot descriptor leaves using `pk(...)` or `multi_a(...)`.
- Compute BIP341 key-path and script-path sighashes for Taproot spends.
- Extract finalized PSBTs into signed transactions.

The complete PSBT signing/finalization paths are P2PKH, P2WPKH, single-key P2WSH with `SIGHASH_ALL`, BIP86-style Taproot key-path spends with `SIGHASH_DEFAULT` or `SIGHASH_ALL`, and single-leaf Taproot script-path spends with `pk(...)` or `multi_a(...)` leaves.

Still pending:

- Taproot script-path descriptor signing for multi-branch trees with Merkle inclusion proofs.
