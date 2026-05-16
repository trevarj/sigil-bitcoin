# Getting Started

Build the workspace before generating API docs:

```sh
./scripts/docs-build.sh
```

Use the packages directly from a Sigil program:

```scheme
(import (sigil bitcoin keys)
        (sigil bitcoin tx)
        (sigil bitcoin script)
        (sigil bitcoin miniscript))
```

Common entry points:

- Use `(sigil bitcoin encoding)` for address and wire-format codecs.
- Use `(sigil bitcoin keys)` when deriving keys, addresses, and mnemonics.
- Use `(sigil bitcoin tx)` when constructing, signing, finalizing, or extracting transactions.
- Use `(sigil bitcoin miniscript)` when parsing descriptors or expanding wallet policies.

Descriptor signing flow:

```scheme
(define desc
  (descriptor-parse
    "tr(0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,multi_a(1,0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,03f028892bad7ed57d2fb57bf33081d5cfcf6f9ed3d3d7f159c2e2fff579dc341a))"))

(define plan (descriptor-derive-psbt-plan desc 0 0))
(define annotated (descriptor-psbt-plan-annotate-input psbt 0 plan))
(define signed (descriptor-psbt-plan-sign-input annotated 0 plan private-key))
(define finalized (descriptor-psbt-plan-finalize-input signed 0 plan))
```

Serve the generated site locally:

```sh
./scripts/docs-serve.sh
```
