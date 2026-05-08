#include <sigil/sigil.h>

#ifdef __EMSCRIPTEN__
void sigil__init_sigil_secp256k1_module(SigilVM *vm)
{
    (void)vm;
}
#else

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include <secp256k1.h>
#include <secp256k1_extrakeys.h>
#include <secp256k1_schnorrsig.h>

static secp256k1_context *secp_ctx = NULL;

static int ensure_context(SigilVM *vm)
{
    if (secp_ctx) return 1;

    secp_ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN |
                                        SECP256K1_CONTEXT_VERIFY);
    if (!secp_ctx) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1: failed to create context");
        return 0;
    }

    return 1;
}

static int read_bv_exact(SigilVM *vm, Value v, size_t want, const char *name,
                         const unsigned char **out)
{
    if (!sigil_is_bytevector(v)) {
        sigil__vm_error(vm, SIGIL_ERR_TYPE, name);
        return 0;
    }

    if (sigil_bytevector_length(v) != want) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME, name);
        return 0;
    }

    *out = sigil_bytevector_data(v);
    return 1;
}

static Value make_bv(SigilVM *vm, const unsigned char *data, size_t len)
{
    Value out = sigil_make_bytevector(vm, len);
    if (out == SIGIL_UNDEFINED) return out;

    memcpy(sigil_bytevector_data(out), data, len);
    return out;
}

static int parse_serialized_pubkey(SigilVM *vm, Value v, secp256k1_pubkey *pubkey,
                                   const char *name)
{
    if (!sigil_is_bytevector(v)) {
        sigil__vm_error(vm, SIGIL_ERR_TYPE, name);
        return 0;
    }

    size_t len = sigil_bytevector_length(v);
    if (len != 33 && len != 65) {
        return 0;
    }

    return secp256k1_ec_pubkey_parse(secp_ctx, pubkey,
                                     sigil_bytevector_data(v), len) == 1;
}

static Value serialize_pubkey_compressed(SigilVM *vm,
                                         const secp256k1_pubkey *pubkey)
{
    unsigned char out[33];
    size_t out_len = sizeof(out);

    if (secp256k1_ec_pubkey_serialize(secp_ctx, out, &out_len, pubkey,
                                      SECP256K1_EC_COMPRESSED) != 1 ||
        out_len != sizeof(out)) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1: failed to serialize public key");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, out, sizeof(out));
}

static Value native_seckey_verify(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;
    if (!sigil_is_bytevector(args[0]) || sigil_bytevector_length(args[0]) != 32) {
        return SIGIL_FALSE;
    }

    return sigil_bool(secp256k1_ec_seckey_verify(
        secp_ctx, sigil_bytevector_data(args[0])) == 1);
}

static Value native_pubkey_create(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *seckey;
    if (!read_bv_exact(vm, args[0], 32,
                       "secp256k1-pubkey-create: expected 32-byte seckey",
                       &seckey)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_pubkey pubkey;
    if (secp256k1_ec_pubkey_create(secp_ctx, &pubkey, seckey) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-create: invalid seckey");
        return SIGIL_UNDEFINED;
    }

    return serialize_pubkey_compressed(vm, &pubkey);
}

static Value native_pubkey_parse(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_pubkey pubkey;
    if (!parse_serialized_pubkey(vm, args[0], &pubkey,
                                 "secp256k1-pubkey-parse: expected bytevector")) {
        return SIGIL_FALSE;
    }

    return make_bv(vm, pubkey.data, sizeof(pubkey.data));
}

static Value native_pubkey_xonly(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_pubkey pubkey;
    if (!parse_serialized_pubkey(
            vm, args[0], &pubkey,
            "secp256k1-pubkey-xonly: expected bytevector")) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-xonly: invalid pubkey");
        return SIGIL_UNDEFINED;
    }

    secp256k1_xonly_pubkey xonly;
    int parity = 0;
    if (secp256k1_xonly_pubkey_from_pubkey(secp_ctx, &xonly, &parity,
                                           &pubkey) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-xonly: conversion failed");
        return SIGIL_UNDEFINED;
    }

    unsigned char out[32];
    if (secp256k1_xonly_pubkey_serialize(secp_ctx, out, &xonly) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-xonly: serialize failed");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, out, sizeof(out));
}

static Value native_pubkey_tweak_add(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_pubkey pubkey;
    if (!parse_serialized_pubkey(
            vm, args[0], &pubkey,
            "secp256k1-pubkey-tweak-add: expected bytevector")) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-tweak-add: invalid pubkey");
        return SIGIL_UNDEFINED;
    }

    const unsigned char *tweak;
    if (!read_bv_exact(vm, args[1], 32,
                       "secp256k1-pubkey-tweak-add: expected 32-byte tweak",
                       &tweak)) {
        return SIGIL_UNDEFINED;
    }

    if (secp256k1_ec_pubkey_tweak_add(secp_ctx, &pubkey, tweak) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-tweak-add: tweak failed");
        return SIGIL_UNDEFINED;
    }

    return serialize_pubkey_compressed(vm, &pubkey);
}

static Value native_pubkey_tweak_mul(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_pubkey pubkey;
    if (!parse_serialized_pubkey(
            vm, args[0], &pubkey,
            "secp256k1-pubkey-tweak-mul: expected bytevector")) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-tweak-mul: invalid pubkey");
        return SIGIL_UNDEFINED;
    }

    const unsigned char *tweak;
    if (!read_bv_exact(vm, args[1], 32,
                       "secp256k1-pubkey-tweak-mul: expected 32-byte tweak",
                       &tweak)) {
        return SIGIL_UNDEFINED;
    }

    if (secp256k1_ec_pubkey_tweak_mul(secp_ctx, &pubkey, tweak) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-tweak-mul: tweak failed");
        return SIGIL_UNDEFINED;
    }

    return serialize_pubkey_compressed(vm, &pubkey);
}

static Value native_pubkey_combine(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_pubkey pubkey_a;
    secp256k1_pubkey pubkey_b;
    if (!parse_serialized_pubkey(
            vm, args[0], &pubkey_a,
            "secp256k1-pubkey-combine: expected first pubkey")) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-combine: invalid first pubkey");
        return SIGIL_UNDEFINED;
    }
    if (!parse_serialized_pubkey(
            vm, args[1], &pubkey_b,
            "secp256k1-pubkey-combine: expected second pubkey")) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-combine: invalid second pubkey");
        return SIGIL_UNDEFINED;
    }

    const secp256k1_pubkey *pubkeys[2] = {&pubkey_a, &pubkey_b};
    secp256k1_pubkey combined;
    if (secp256k1_ec_pubkey_combine(secp_ctx, &combined, pubkeys, 2) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-pubkey-combine: combine failed");
        return SIGIL_UNDEFINED;
    }

    return serialize_pubkey_compressed(vm, &combined);
}

static Value native_xonly_pubkey_tweak_add(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *xonly_data;
    const unsigned char *tweak;
    if (!read_bv_exact(vm, args[0], 32,
                       "secp256k1-xonly-pubkey-tweak-add: expected 32-byte xonly pubkey",
                       &xonly_data) ||
        !read_bv_exact(vm, args[1], 32,
                       "secp256k1-xonly-pubkey-tweak-add: expected 32-byte tweak",
                       &tweak)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_xonly_pubkey xonly;
    if (secp256k1_xonly_pubkey_parse(secp_ctx, &xonly, xonly_data) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-xonly-pubkey-tweak-add: invalid xonly pubkey");
        return SIGIL_UNDEFINED;
    }

    secp256k1_pubkey tweaked;
    if (secp256k1_xonly_pubkey_tweak_add(secp_ctx, &tweaked, &xonly, tweak) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-xonly-pubkey-tweak-add: tweak failed");
        return SIGIL_UNDEFINED;
    }

    return serialize_pubkey_compressed(vm, &tweaked);
}

static Value native_seckey_tweak_add(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *seckey;
    const unsigned char *tweak;
    if (!read_bv_exact(vm, args[0], 32,
                       "secp256k1-seckey-tweak-add: expected 32-byte seckey",
                       &seckey) ||
        !read_bv_exact(vm, args[1], 32,
                       "secp256k1-seckey-tweak-add: expected 32-byte tweak",
                       &tweak)) {
        return SIGIL_UNDEFINED;
    }

    unsigned char out[32];
    memcpy(out, seckey, sizeof(out));
    if (secp256k1_ec_seckey_tweak_add(secp_ctx, out, tweak) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-seckey-tweak-add: tweak failed");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, out, sizeof(out));
}

static Value native_ecdsa_sign(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *seckey;
    const unsigned char *msghash;
    if (!read_bv_exact(vm, args[0], 32,
                       "secp256k1-ecdsa-sign: expected 32-byte seckey",
                       &seckey) ||
        !read_bv_exact(vm, args[1], 32,
                       "secp256k1-ecdsa-sign: expected 32-byte message hash",
                       &msghash)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_ecdsa_signature sig;
    if (secp256k1_ecdsa_sign(secp_ctx, &sig, msghash, seckey, NULL, NULL) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-ecdsa-sign: signing failed");
        return SIGIL_UNDEFINED;
    }

    unsigned char out[64];
    secp256k1_ecdsa_signature_serialize_compact(secp_ctx, out, &sig);
    return make_bv(vm, out, sizeof(out));
}

static Value native_ecdsa_verify(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *sig_bytes;
    const unsigned char *msghash;
    if (!read_bv_exact(vm, args[0], 64,
                       "secp256k1-ecdsa-verify: expected 64-byte signature",
                       &sig_bytes) ||
        !read_bv_exact(vm, args[1], 32,
                       "secp256k1-ecdsa-verify: expected 32-byte message hash",
                       &msghash)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_pubkey pubkey;
    if (!parse_serialized_pubkey(vm, args[2], &pubkey,
                                 "secp256k1-ecdsa-verify: expected pubkey")) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-ecdsa-verify: invalid pubkey");
        return SIGIL_UNDEFINED;
    }

    secp256k1_ecdsa_signature sig;
    if (secp256k1_ecdsa_signature_parse_compact(secp_ctx, &sig, sig_bytes) != 1) {
        return SIGIL_FALSE;
    }

    return sigil_bool(secp256k1_ecdsa_verify(secp_ctx, &sig, msghash,
                                             &pubkey) == 1);
}

static Value native_ecdsa_signature_parse_der(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;
    if (!sigil_is_bytevector(args[0])) {
        sigil__vm_error(vm, SIGIL_ERR_TYPE,
                        "secp256k1-ecdsa-signature-parse-der: expected bytevector");
        return SIGIL_UNDEFINED;
    }

    secp256k1_ecdsa_signature sig;
    if (secp256k1_ecdsa_signature_parse_der(
            secp_ctx, &sig, sigil_bytevector_data(args[0]),
            sigil_bytevector_length(args[0])) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-ecdsa-signature-parse-der: parse failed");
        return SIGIL_UNDEFINED;
    }

    unsigned char out[64];
    secp256k1_ecdsa_signature_serialize_compact(secp_ctx, out, &sig);
    return make_bv(vm, out, sizeof(out));
}

static Value native_ecdsa_signature_serialize_der(SigilVM *vm, int argc,
                                                  Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *sig_bytes;
    if (!read_bv_exact(
            vm, args[0], 64,
            "secp256k1-ecdsa-signature-serialize-der: expected 64-byte signature",
            &sig_bytes)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_ecdsa_signature sig;
    if (secp256k1_ecdsa_signature_parse_compact(secp_ctx, &sig, sig_bytes) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-ecdsa-signature-serialize-der: parse failed");
        return SIGIL_UNDEFINED;
    }

    unsigned char out[72];
    size_t out_len = sizeof(out);
    if (secp256k1_ecdsa_signature_serialize_der(secp_ctx, out, &out_len,
                                                &sig) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-ecdsa-signature-serialize-der: serialize failed");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, out, out_len);
}

static int read_keypair(SigilVM *vm, Value v, secp256k1_keypair *keypair,
                        const char *name)
{
    const unsigned char *data;
    if (!read_bv_exact(vm, v, sizeof(keypair->data), name, &data)) {
        return 0;
    }

    memcpy(keypair->data, data, sizeof(keypair->data));
    return 1;
}

static Value native_keypair_create(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *seckey;
    if (!read_bv_exact(vm, args[0], 32,
                       "secp256k1-keypair-create: expected 32-byte seckey",
                       &seckey)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_keypair keypair;
    if (secp256k1_keypair_create(secp_ctx, &keypair, seckey) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-keypair-create: invalid seckey");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, keypair.data, sizeof(keypair.data));
}

static Value native_keypair_pub(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_keypair keypair;
    if (!read_keypair(vm, args[0], &keypair,
                      "secp256k1-keypair-pub: expected 96-byte keypair")) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_pubkey pubkey;
    secp256k1_keypair_pub(secp_ctx, &pubkey, &keypair);
    return serialize_pubkey_compressed(vm, &pubkey);
}

static Value keypair_xonly_pub_value(SigilVM *vm, const secp256k1_keypair *keypair,
                                     int *parity)
{
    secp256k1_xonly_pubkey xonly;
    if (secp256k1_keypair_xonly_pub(secp_ctx, &xonly, parity, keypair) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-keypair-xonly-pub: conversion failed");
        return SIGIL_UNDEFINED;
    }

    unsigned char out[32];
    if (secp256k1_xonly_pubkey_serialize(secp_ctx, out, &xonly) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-keypair-xonly-pub: serialize failed");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, out, sizeof(out));
}

static Value native_keypair_xonly_pub(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_keypair keypair;
    if (!read_keypair(vm, args[0], &keypair,
                      "secp256k1-keypair-xonly-pub: expected 96-byte keypair")) {
        return SIGIL_UNDEFINED;
    }

    int parity = 0;
    return keypair_xonly_pub_value(vm, &keypair, &parity);
}

static Value native_keypair_xonly_pub_with_parity(SigilVM *vm, int argc,
                                                  Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_keypair keypair;
    if (!read_keypair(
            vm, args[0],
            &keypair,
            "secp256k1-keypair-xonly-pub-with-parity: expected 96-byte keypair")) {
        return SIGIL_UNDEFINED;
    }

    int parity = 0;
    Value xonly = keypair_xonly_pub_value(vm, &keypair, &parity);
    if (xonly == SIGIL_UNDEFINED) return xonly;

    return sigil_cons(vm, xonly, sigil_fixnum(parity));
}

static Value native_keypair_xonly_tweak_add(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_keypair keypair;
    const unsigned char *tweak;
    if (!read_keypair(
            vm, args[0],
            &keypair,
            "secp256k1-keypair-xonly-tweak-add: expected 96-byte keypair") ||
        !read_bv_exact(
            vm, args[1], 32,
            "secp256k1-keypair-xonly-tweak-add: expected 32-byte tweak",
            &tweak)) {
        return SIGIL_UNDEFINED;
    }

    if (secp256k1_keypair_xonly_tweak_add(secp_ctx, &keypair, tweak) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-keypair-xonly-tweak-add: tweak failed");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, keypair.data, sizeof(keypair.data));
}

static Value native_schnorrsig_sign32(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    secp256k1_keypair keypair;
    const unsigned char *msg;
    if (!read_keypair(vm, args[0],
                      &keypair,
                      "secp256k1-schnorrsig-sign32: expected 96-byte keypair") ||
        !read_bv_exact(vm, args[1], 32,
                       "secp256k1-schnorrsig-sign32: expected 32-byte message",
                       &msg)) {
        return SIGIL_UNDEFINED;
    }

    unsigned char out[64];
    if (secp256k1_schnorrsig_sign32(secp_ctx, out, msg, &keypair, NULL) != 1) {
        sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                        "secp256k1-schnorrsig-sign32: signing failed");
        return SIGIL_UNDEFINED;
    }

    return make_bv(vm, out, sizeof(out));
}

static Value native_schnorrsig_verify(SigilVM *vm, int argc, Value *args)
{
    (void)argc;
    if (!ensure_context(vm)) return SIGIL_UNDEFINED;

    const unsigned char *sig;
    const unsigned char *msg;
    const unsigned char *xonly_data;
    if (!read_bv_exact(vm, args[0], 64,
                       "secp256k1-schnorrsig-verify: expected 64-byte signature",
                       &sig) ||
        !read_bv_exact(vm, args[1], 32,
                       "secp256k1-schnorrsig-verify: expected 32-byte message",
                       &msg) ||
        !read_bv_exact(vm, args[2], 32,
                       "secp256k1-schnorrsig-verify: expected 32-byte xonly pubkey",
                       &xonly_data)) {
        return SIGIL_UNDEFINED;
    }

    secp256k1_xonly_pubkey xonly;
    if (secp256k1_xonly_pubkey_parse(secp_ctx, &xonly, xonly_data) != 1) {
        return SIGIL_FALSE;
    }

    return sigil_bool(secp256k1_schnorrsig_verify(
        secp_ctx, sig, msg, 32, &xonly) == 1);
}

#define REGISTER_AND_EXPORT(name, func, arity, doc) \
    sigil_module_register_native(vm, name, func, arity, doc); \
    sigil_module_export(vm, name)

void sigil__init_sigil_secp256k1_module(SigilVM *vm)
{
    SigilModule *module = sigil_begin_module(vm, "(sigil secp256k1)");
    if (!module) return;

    REGISTER_AND_EXPORT("secp256k1-seckey-verify?",
                        native_seckey_verify, SIGIL_ARITY_EXACT(1),
                        "Validate a 32-byte secp256k1 secret key");
    REGISTER_AND_EXPORT("secp256k1-pubkey-create",
                        native_pubkey_create, SIGIL_ARITY_EXACT(1),
                        "Derive a compressed public key");
    REGISTER_AND_EXPORT("secp256k1-pubkey-parse",
                        native_pubkey_parse, SIGIL_ARITY_EXACT(1),
                        "Parse a serialized public key");
    REGISTER_AND_EXPORT("secp256k1-pubkey-xonly",
                        native_pubkey_xonly, SIGIL_ARITY_EXACT(1),
                        "Convert a serialized public key to x-only form");
    REGISTER_AND_EXPORT("secp256k1-pubkey-tweak-add",
                        native_pubkey_tweak_add, SIGIL_ARITY_EXACT(2),
                        "Add a tweak to a public key");
    REGISTER_AND_EXPORT("secp256k1-pubkey-tweak-mul",
                        native_pubkey_tweak_mul, SIGIL_ARITY_EXACT(2),
                        "Multiply a public key by a scalar tweak");
    REGISTER_AND_EXPORT("secp256k1-pubkey-combine",
                        native_pubkey_combine, SIGIL_ARITY_EXACT(2),
                        "Add two public keys");
    REGISTER_AND_EXPORT("secp256k1-xonly-pubkey-tweak-add",
                        native_xonly_pubkey_tweak_add, SIGIL_ARITY_EXACT(2),
                        "Add an x-only tweak to an x-only public key");
    REGISTER_AND_EXPORT("secp256k1-seckey-tweak-add",
                        native_seckey_tweak_add, SIGIL_ARITY_EXACT(2),
                        "Add a tweak to a secret key");
    REGISTER_AND_EXPORT("secp256k1-ecdsa-sign",
                        native_ecdsa_sign, SIGIL_ARITY_EXACT(2),
                        "Sign a 32-byte message hash with ECDSA");
    REGISTER_AND_EXPORT("secp256k1-ecdsa-verify",
                        native_ecdsa_verify, SIGIL_ARITY_EXACT(3),
                        "Verify a compact ECDSA signature");
    REGISTER_AND_EXPORT("secp256k1-ecdsa-signature-parse-der",
                        native_ecdsa_signature_parse_der, SIGIL_ARITY_EXACT(1),
                        "Parse DER ECDSA signature to compact form");
    REGISTER_AND_EXPORT("secp256k1-ecdsa-signature-serialize-der",
                        native_ecdsa_signature_serialize_der,
                        SIGIL_ARITY_EXACT(1),
                        "Serialize compact ECDSA signature to DER");
    REGISTER_AND_EXPORT("secp256k1-schnorrsig-sign32",
                        native_schnorrsig_sign32, SIGIL_ARITY_EXACT(2),
                        "Sign a 32-byte message with Schnorr");
    REGISTER_AND_EXPORT("secp256k1-schnorrsig-verify",
                        native_schnorrsig_verify, SIGIL_ARITY_EXACT(3),
                        "Verify a Schnorr signature");
    REGISTER_AND_EXPORT("secp256k1-keypair-create",
                        native_keypair_create, SIGIL_ARITY_EXACT(1),
                        "Create a secp256k1 keypair");
    REGISTER_AND_EXPORT("secp256k1-keypair-pub",
                        native_keypair_pub, SIGIL_ARITY_EXACT(1),
                        "Extract a compressed public key from a keypair");
    REGISTER_AND_EXPORT("secp256k1-keypair-xonly-pub",
                        native_keypair_xonly_pub, SIGIL_ARITY_EXACT(1),
                        "Extract a 32-byte x-only public key from a keypair");
    REGISTER_AND_EXPORT("secp256k1-keypair-xonly-pub-with-parity",
                        native_keypair_xonly_pub_with_parity,
                        SIGIL_ARITY_EXACT(1),
                        "Extract a 32-byte x-only public key and parity from a keypair");
    REGISTER_AND_EXPORT("secp256k1-keypair-xonly-tweak-add",
                        native_keypair_xonly_tweak_add,
                        SIGIL_ARITY_EXACT(2),
                        "Add an x-only tweak to a keypair");

    sigil_end_module(vm);
}

#undef REGISTER_AND_EXPORT

#endif
