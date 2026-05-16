# Standards Audit Task List

Audit date: 2026-05-16

Scope: full repository scan against `AGENTS.md` after adding the project agent
standards.

Verification:

- `./scripts/test-all.sh` passes as a plain run. It discovers the Guix
  `libsecp256k1` library path and runs root tests plus secp256k1, keys, tx,
  miniscript, and wasm checks.
- The root workspace test run now reports 192 real passing tests and no
  secp256k1 skip-style placeholder tests.
- `./scripts/wasm-test.sh` passes without printing the old fatal-looking WASI
  signal diagnostics during successful builds. `wasmtime` was not on `PATH`, so
  the optional runtime smoke test was skipped.
- `./scripts/standards-check.sh` reports zero generated API placeholders, zero
  tools-side internal `;;;` comments, zero unexpected underscore filenames, and
  four vector files.
- `./scripts/docs-build.sh` completes successfully and refreshes `public/`.
  It still emits an intermittent Sigil auto-compile bytecode diagnostic while
  continuing to a zero exit status.
- `jq empty tests/vectors/*.json` passes.
- `git diff --check` passes.

## High Priority

- [x] Make `./scripts/test-all.sh` self-contained for native harnesses.
  It should discover or inject the Guix `libsecp256k1` library path so a plain
  script run does not fail at `sigil-bitcoin-keys`, `sigil-bitcoin-tx`, or
  `sigil-bitcoin-miniscript` native tests.

- [x] Fix or suppress the wasm signal diagnostics in the demo wasm build.
  `./scripts/wasm-test.sh` succeeds, but the compiler emits WASI signal errors
  from sibling Sigil `terminal.c`. A standards-compliant verification path
  should not print fatal-looking diagnostics during a passing run.

- [x] Add public API docstrings for generated `No docstring yet` exports.
  The initial audit found 52 missing docstrings in
  `public/api/sigil/bitcoin/psbt.html` and 9 in
  `public/api/sigil/bitcoin/miniscript.html`. The main source gaps are facade
  re-exports and generated struct/accessor aliases; either add source
  docstrings or teach the docs generator to inherit docs from origin modules.

- [x] Create durable test vector storage under `tests/vectors/`.
  `docs/plan.md` says BIP vectors should live in `tests/vectors/`, but the
  directory is currently empty and vectors are embedded directly in test files.
  Move or mirror BIP, Bitcoin Core, rust-bitcoin, and rust-miniscript fixtures
  into stable vector files where practical.

## Medium Priority

- [x] Increase inline spec coverage for public and nontrivial Sigil functions.
  Several important files have many `define` forms with few or no inline
  `(: ...)` specs, especially `tools/docs-site.sgl`,
  `tools/docs-serve.sgl`, `packages/sigil-bitcoin-demo/src/sigil/bitcoin/demo.sgl`,
  `packages/sigil-bitcoin-encoding/src/sigil/bitcoin/encoding.sgl`,
  `packages/sigil-bitcoin-primitives/src/sigil/bitcoin/primitives.sgl`,
  and PSBT internals under `packages/sigil-bitcoin-tx/src/sigil/bitcoin/psbt/`.

- [x] Reduce root direct-runner skip noise for native secp256k1-dependent tests.
  Root tests pass by recording skip-style tests when the native module is not
  linked, while package harnesses exercise the real behavior. Either make the
  root runner native-aware or separate expected native skips more explicitly in
  reporting.

- [x] Replace `;;;` internal comments with `;;` where they are not exported API
  docs. One visible example is the internal implementation note in
  `tools/docs-site.sgl`; source files should reserve `;;;` for module headers
  and exported doc comments.

- [x] Add explicit invalid-input coverage for docs/demo dispatch surfaces.
  The core packages have strong invalid-input coverage, but browser tool
  dispatch and static docs generation paths should also cover malformed inputs,
  unknown tools, and unexpected metadata shapes.

- [x] Normalize the one underscore-containing source-adjacent filename or
  document it as an exception:
  `packages/sigil-bitcoin-demo/wasm-include/sigil_mbedtls_config.h`.
  `AGENTS.md` says to use hyphenated filenames.

## Lower Priority

- [x] Add a lightweight standards check script.
  A script could report missing public docstrings, `;;;` internal comments,
  underscore filenames, empty `tests/vectors/`, and spec-count hotspots before
  handoff.

- [x] Add a Bitcoin implementation checklist template.
  This would make the required final handoff fields concrete: BIPs read,
  external APIs checked, vectors used, invalid cases added, and round-trips
  covered.

- [x] Revisit old planning docs for stale paths and workflow drift.
  `docs/phase0.md` has been refreshed for current verification entry points,
  and `docs/plan.md` now points at the consolidated test script, standards
  checker, and durable vector layout.
