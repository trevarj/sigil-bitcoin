;; sigil-bitcoin Development Environment
;; Use with: guix shell -m manifest.scm
;;
;; Sigil is installed via binary download (not in Guix), so only
;; system-level dependencies go here. The sigil binary at ~/.local/bin/sigil
;; is used directly.

(specifications->manifest
  '("libsecp256k1"        ;; secp256k1 ECDSA + Schnorr (FFI target)
    "gcc-toolchain"       ;; for building sigil-crypto native extensions
    "make"
    "pkg-config"))
