# Getting Started

Build the workspace before generating API docs:

```sh
./scripts/docs-build.sh
```

Use the packages directly from a Sigil program:

```scheme
(import (sigil bitcoin keys)
        (sigil bitcoin tx)
        (sigil bitcoin script))
```

Common entry points:

- Use `(sigil bitcoin encoding)` for address and wire-format codecs.
- Use `(sigil bitcoin keys)` when deriving keys, addresses, and mnemonics.
- Use `(sigil bitcoin tx)` when constructing, signing, finalizing, or extracting transactions.
- Use `(sigil bitcoin miniscript)` when parsing descriptors or expanding wallet policies.

Serve the generated site locally:

```sh
./scripts/docs-serve.sh
```
