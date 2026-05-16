# Phase 0 — Complete

## What was set up

- `~/Workspace/sigil/` — all cloned Sigil source repos:
  - `sigil/` — main language repo (v0.15.0)
  - `sigil-crypto/` — cryptographic primitives (mbedTLS-backed)
  - `sigil-ffi/` — dynamic FFI (dyncall-backed)
  - `sigil-build/` — build system and package manager

- `/home/trev/Workspace/sigil/sigil-bitcoin/` — Bitcoin library monorepo:
  - `manifest.scm` — Guix dev shell (libsecp256k1 + toolchain)
  - `package.sgl` — workspace definition
  - `docs/plan.md` — full implementation plan
  - `packages/` — scaffolded package dirs for layers 0-6
  - `tests/vectors/` — for BIP test vectors

- Sigil is provided by the project Guix development environment and local
  redirects in `dev-redirects.sgl`.

## Current Verification Entry Points

- `./scripts/test-all.sh` runs root tests, native package harnesses, and wasm
  validation.
- `./scripts/docs-build.sh` rebuilds generated public docs.
- `./scripts/standards-check.sh` reports standards audit counters.

## Phase 1 (next) — Unblock primitives in sigil-crypto

Three native additions to `~/Workspace/sigil/sigil-crypto/`:

1. **RIPEMD-160**: Add `MBEDTLS_RIPEMD160_C` to `vendor/mbedtls/sigil_mbedtls_config.h`,
   add `native_ripemd160` to `native/crypto.c`, register in `sigil__init_sigil_crypto_module`.

2. **HMAC-SHA512**: Add `native_hmac_sha512_bytes` to `native/crypto.c` following the pattern
   of `native_hmac_sha256_bytes`. Config already has `MBEDTLS_SHA512_C`.

3. **Bignums (mbedTLS mpi)**: Expose `mbedtls_mpi_*` operations as native functions.
   Config already has `MBEDTLS_BIGNUM_C`. Need: bv->mpi, mpi->bv (32-byte), add/sub/mul/div/mod/inv/cmp.

After Phase 1, all remaining layers can be built in pure Sigil.
