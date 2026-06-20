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
  Every exported function must include example usage in its doc comment unless
  it is a generated accessor or predicate whose usage is already shown by the
  exported constructor or workflow docs.
- Internal comments and section comments use `;;`, not `;;;`.
- Add inline `(: ...)` specs inside `define` bodies when adding public or
  nontrivial procedures. Specs must include an explicit return type.
- Comments should explain intent, consensus rules, or non-obvious behavior, not
  restate the code.
- Public APIs should be small, typed by predicates, and idiomatic for Sigil.
- Public API work must consider the whole package surface, not only the function
  being edited. Prefer the smallest API that balances functionality,
  correctness, and ease of use. Before adding or exposing exports, compare
  existing package facades, naming, argument order, return shapes, and
  rust-bitcoin-family API precedents, then avoid duplicative or low-level
  exports unless they are needed for real workflows.

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

## Node Runtime Notes

`sigil-bitcoin-node` is chain-config driven. Keep Bitcoin behavior unchanged
when adding SigilCoin support, and put network constants, seeds, ports, magic,
genesis data, activation heights, and similar policy in chain config records
rather than hard-coding Bitcoin assumptions in sync or peer logic.

Current CLI surface:

- `status`
- `peers bootstrap|add|list|summary|remove|test`
- `probe`
- `header-sync`
- `block-sync`
- `sync`
- `run`

The node currently persists peers, headers, blocks, validation state, status,
and run-loop metadata in SQLite. Prefer extending that persisted state over
adding ad hoc sidecar files.

Live P2P guidance:

- Prefer `bitcoin-signet` for lightweight live probes.
- Use bounded `--resolve-timeout`, `--connect-timeout`, `--read-timeout`, and
  script-level deadlines for live networking.
- If direct peer access is blocked by VPN or local network policy, try native
  SOCKS5 support with `--socks5 127.0.0.1:9050`; do not assume `torsocks`
  works for this runtime.
- Treat live peer failures as environmental unless mocked P2P and node harnesses
  fail too.
- Use `scripts/live-testnet-probe.sh --chain bitcoin-signet` for bounded live
  probes. It also accepts `--socks5 127.0.0.1:9050`, or
  `SIGIL_BITCOIN_LIVE_SOCKS5=127.0.0.1:9050`.

Consensus gotcha from live signet testing: BIP34 coinbase height commitments
must accept minimally encoded script-number small-int opcodes `OP_0` through
`OP_16`, not only bytevector pushes.

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

```sh
cd packages/sigil-bitcoin-consensus
guix shell -m ../../manifest.scm -- sigil test test/test-consensus.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

```sh
cd packages/sigil-bitcoin-p2p
guix shell -m ../../manifest.scm -- sigil test test/test-p2p.sgl \
  --redirects ../../dev-redirects.sgl --no-color
```

```sh
cd packages/sigil-bitcoin-node
guix shell -m ../../manifest.scm -- ../../../sigil/build/dev/bin/sigil test \
  test/test-node.sgl --redirects ../../dev-redirects.sgl --no-color
```

For substantial Bitcoin, native, cross-package, or release-facing changes, run:

```sh
./scripts/test-all.sh
```

`./scripts/test-all.sh` includes the root workspace tests, native package
harnesses, consensus/P2P/node harnesses, and the WebAssembly smoke test. The
Wasmtime smoke path is expected to run from the manifest environment; if it is
skipped, report the missing tool explicitly.

Root workspace tests can intentionally skip native-only assertions. Package
harnesses are authoritative for native secp256k1, keys, transaction,
miniscript, consensus, P2P, and node behavior.

If native package harnesses fail to locate `libsecp256k1`, run them from the
Guix manifest environment and report the exact command used.

## Documentation and Generated Files

- Keep concise docs under `docs/site/`.
- Do not write new broad README-style documentation unless requested.
- If docs, public APIs, generated API pages, or toolbench behavior change, run:

```sh
./scripts/docs-build.sh
```

The prior docs macro blocker is fixed; treat new docs-build failures as fresh
regressions unless the error clearly points at a new upstream/runtime issue.

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
