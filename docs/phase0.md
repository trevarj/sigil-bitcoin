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

## Phase 1 — Complete

The required native additions were upstreamed to `sigil-crypto`:

- **RIPEMD-160**: `ripemd160`
- **HMAC-SHA512**: `hmac-sha512-bytes`
- **Bignums (mbedTLS mpi)**: `mpi-add`, `mpi-sub`, `mpi-mul`,
  `mpi-div`, `mpi-mod`, `mpi-mod-add`, `mpi-inv-mod`, `mpi-cmp`,
  `mpi-is-zero?`, `mpi-shift-l`, and `mpi-shift-r`

`sigil-bitcoin-primitives` now depends on upstream `sigil-crypto` and uses the
native `ripemd160` binding for `HASH160` when the current runtime links it,
with a private compatibility fallback for direct test runners using stale
bundled crypto natives.
