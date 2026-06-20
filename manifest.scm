;; sigil-bitcoin Development Environment
;; Use with: guix shell -m manifest.scm
;;
;; Sigil is installed via binary download (not in Guix), so only
;; system-level dependencies go here. The sigil binary at ~/.local/bin/sigil
;; is used directly.

(use-modules (gnu packages base)
             (gnu packages elf)
             (gnu packages gcc)
             (guix build-system copy)
             (guix download)
             ((guix licenses) #:prefix license:)
             (guix packages)
             (gnu packages))

(define wasmtime-bin
  (package
    (name "wasmtime-bin")
    (version "45.0.2")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "https://github.com/bytecodealliance/wasmtime/releases/download/v"
         version
         "/wasmtime-v"
         version
         "-x86_64-linux.tar.xz"))
       (sha256
        (base32 "1jffmkqj1zxw1mw6a4s62jg5daf9z19ykg31s7y2099cv7xlzp0s"))))
    (build-system copy-build-system)
    (native-inputs
     (list patchelf))
    (inputs
     `(("gcc:lib" ,gcc "lib")
       ("glibc" ,glibc)))
    (arguments
     '(#:install-plan '(("wasmtime" "bin/"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'patch-binary
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin/wasmtime"))
                    (gcc-lib (assoc-ref inputs "gcc:lib"))
                    (glibc (assoc-ref inputs "glibc")))
               ;; Upstream's binary is dynamically linked for FHS systems.
               (invoke "patchelf"
                       "--set-interpreter"
                       (string-append glibc "/lib/ld-linux-x86-64.so.2")
                       "--set-rpath"
                       (string-append glibc "/lib:" gcc-lib "/lib")
                       bin)))))))
    (home-page "https://wasmtime.dev/")
    (synopsis "Standalone WebAssembly runtime")
    (description
     "Wasmtime is a standalone runtime for WebAssembly and WASI modules.")
    (license license:asl2.0)))

(packages->manifest
 (append
  (specifications->packages
   '("libsecp256k1"        ;; secp256k1 ECDSA + Schnorr (FFI target)
     "zig"                 ;; wasm32-wasi builds for browser demos
     "wabt"                ;; wasm-objdump validation for browser demos
     "gcc-toolchain"       ;; for building sigil-crypto native extensions
     "make"
     "pkg-config"))
  (list wasmtime-bin)))
