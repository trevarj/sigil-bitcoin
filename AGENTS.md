# Agent Instructions

## Project Goal

`sigil-bitcoin` is a rust-bitcoin-like Bitcoin library ecosystem for Sigil.
Prioritize correctness, clear public APIs, and high test coverage over speed.

These instructions apply to the whole repository unless a more specific
`AGENTS.md` exists in a subdirectory.

## Development Environment

- The user runs GNU Guix System. Do not use `guix install`.
- Use `guix shell -m manifest.scm -- <command>` for project commands that need
  declared dependencies.
- Do not suggest or use apt, dnf, pacman, brew, global npm, global pip, or other
  host package managers.
- Prefer `rg` for content search and `fd` for file search.
- Prefer existing scripts over ad hoc command sequences.
- Before using a tool that may not be on `PATH`, check for it or run it through
  the Guix manifest.

## Sigil Standards

Follow the Sigil implementation standards from the sibling checkout:
`/home/trev/Workspace/sigil/sigil/CLAUDE.md`.

Key rules for this repo:

- Use hyphenated filenames.
- Exception: `packages/sigil-bitcoin-demo/wasm-include/sigil_mbedtls_config.h`
  mirrors the mbedTLS configuration filename expected by included C headers.
- Use `.sgl` for Sigil source files.
- Prefer existing modules, helpers, and package layering before adding new
  utilities.
- Keep package boundaries clear. Do not reach across layers when a facade module
  or shared helper already owns the behavior.
- Exported Sigil procedures should have `;;;` doc comments suitable for API docs.
- Internal comments and section comments use `;;`, not `;;;`.
- Add inline `(: ...)` specs inside `define` bodies when adding public or
  nontrivial procedures. Specs must include an explicit return type.
- Comments should explain intent, consensus rules, or non-obvious behavior, not
  restate the code.
- Public APIs should be small, typed by predicates, and idiomatic for Sigil.

## Bitcoin Standards

Bitcoin-related work has mandatory research and test gates.

- Before implementing Bitcoin behavior, read the relevant BIPs, Bitcoin Core
  behavior or fixtures when applicable, and comparable rust-bitcoin,
  rust-miniscript, or related public APIs.
- Use rust-bitcoin-family APIs as inspiration for concepts, completeness, and
  naming, but prefer idiomatic Sigil records, predicates, bytevectors, errors,
  and existing repo conventions.
- Do not infer consensus, wire encoding, sighash, descriptor, PSBT, address, or
  key behavior from memory alone when a spec or vector exists.
- Validate lengths, ranges, encodings, network constants, and witness/script
  invariants explicitly.
- Preserve unknown/proprietary fields in wire formats unless a spec says
  otherwise.
- Keep consensus-critical and signing code boring, direct, and testable.
- In the final handoff, list the BIPs/specs and external APIs consulted for any
  Bitcoin feature or behavior change.

## Testing and Coverage

Every meaningful behavior change needs tests.

- Prefer BIP vectors, Bitcoin Core fixtures, rust-bitcoin or rust-miniscript
  vectors, and known-answer tests when available.
- Add invalid-input tests for parsers, codecs, key material, signatures,
  sighashes, PSBT maps, descriptors, and script-related behavior.
- Add round-trip tests for serialization, parsing, descriptors, PSBTs, and
  generated addresses where applicable.
- For new public exports, test the exported behavior directly or through a
  higher-level workflow that proves the public contract.
- Run the narrow package harness first, then broader checks when touching shared
  packages or cross-package flows.

Known-good checks:

```sh
guix shell -m manifest.scm -- sigil test --redirects ./dev-redirects.sgl --no-color
```

```sh
cd packages/sigil-secp256k1
guix shell -m ../../manifest.scm -- sigil test test/test-secp256k1.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

```sh
cd packages/sigil-bitcoin-keys
guix shell -m ../../manifest.scm -- sigil test test/test-keys.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

```sh
cd packages/sigil-bitcoin-tx
guix shell -m ../../manifest.scm -- sigil test test/test-tx.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

```sh
cd packages/sigil-bitcoin-miniscript
guix shell -m ../../manifest.scm -- sigil test test/test-miniscript.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

For substantial Bitcoin, native, cross-package, or release-facing changes, run:

```sh
./scripts/test-all.sh
```

If native package harnesses fail to locate `libsecp256k1`, run them from the
Guix manifest environment and report the exact command used.

## Documentation and Generated Files

- Keep concise docs under `docs/site/`.
- Do not write new broad README-style documentation unless requested.
- If docs, public APIs, generated API pages, or toolbench behavior change, run:

```sh
./scripts/docs-build.sh
```

- Commit the resulting `public/` changes together with the source docs/API
  changes.
- If browser demo or WebAssembly-facing behavior changes, run:

```sh
./scripts/wasm-test.sh
```

## Git and Handoff

- Use Conventional Commits when committing:
  `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `build`, `ci`, `perf`,
  or `style`.
- Keep commits focused on one logical change.
- Do not commit automatically. Commit only when the user explicitly asks.
- Never revert user changes unless the user explicitly asks.
- Do not commit secrets or credential files.
- If GPG needs a passphrase, run
  `/home/trev/.codex/bin/codex-gpg-unlock`; never ask for the passphrase in
  chat.
- Final handoff must include changed behavior, tests run, skipped checks with
  reasons, and BIPs/specs/external APIs consulted for Bitcoin changes.
