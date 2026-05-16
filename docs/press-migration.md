# Press Migration

## Status

- Press is the upstream static site generator formerly known as `sigil-publish`.
- Upstream package: `codeberg:sigil/press`.
- Current latest tag found: `v0.1.1`.
- `codeberg:sigil/sigil-publish` does not exist as a public repo.
- Press currently declares old `^0.9.0` ecosystem dependencies and its
  `package.sgl` lacks the modern required `sigil:` field.
- `scripts/docs-build.sh` builds the production site with Press and writes
  `public/`.

## Build

Run:

```sh
guix shell -m manifest.scm -- ./scripts/docs-build.sh
```

The build:

- Fetches Press dependencies under `tools/press-docs/.sigil/deps/` when missing.
- Builds the package docs artifacts.
- Uses `packages/sigil-bitcoin-miniscript/build/dev/lib` as the aggregate API
  docs source because it includes the public Bitcoin modules from dependencies.
- Writes Press output to `public/`.
- Adds the sigil-bitcoin homepage, WebAssembly tool pages, search index, and
  static assets after the Press graph render.

## Remaining Work

- Update or upstream Press metadata for current Sigil:
  add `sigil: "^0.16"` and refresh dependency ranges.
- Decide whether this repo should depend on Press as a normal package once the
  upstream package is current.
- Remove the old `tools/docs-site.sgl` generator after the Press path has been
  used for a release cycle.
