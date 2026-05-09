/*
 * Browser runtime for the sigil-bitcoin demo.
 *
 * This mirrors sigil-web-run, but initializes the native crypto module
 * before Scheme imports run.
 */

#include <sigil/sigil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#define SIGIL_EXPORT EMSCRIPTEN_KEEPALIVE
#else
#define SIGIL_EXPORT __attribute__((visibility("default")))
#endif

extern void sigil__init_sigil_crypto_module(SigilVM *vm);

static SigilVM *g_vm = NULL;
static Value sym_waiting = 0;
static Value sym_exit = 0;

SIGIL_EXPORT
int sigil_web_init(void)
{
    if (g_vm) {
        return 0;
    }

    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    g_vm = sigil_vm_create();
    if (!g_vm) {
        fprintf(stderr, "Error: Failed to create VM\n");
        return 1;
    }

    sigil__init_sigil_crypto_module(g_vm);

    sigil_vm_add_load_path(g_vm, "/lib");

    sym_waiting = sigil_intern_symbol(g_vm, "waiting-for-input", 17);
    sym_exit = sigil_intern_symbol(g_vm, "exit", 4);

    sigil_eval_string(g_vm, "(import (sigil core))");
    const char *err = sigil_error_message(g_vm);
    if (err) {
        fprintf(stderr, "Error loading (sigil core): %s\n", err);
        return 1;
    }

    return 0;
}

SIGIL_EXPORT
int sigil_web_start(void)
{
    if (!g_vm) {
        fprintf(stderr, "Error: VM not initialized\n");
        return -1;
    }

    sigil_error_clear(g_vm);

    Value result = sigil_eval_string(g_vm, "(load \"/lib/main.sgl\")");
    fflush(stdout);

    const char *err = sigil_error_message(g_vm);
    if (err) {
        fprintf(stderr, "Error loading entrypoint: %s\n", err);
        return -1;
    }

    if (sigil_eq(result, sym_waiting)) {
        return 1;
    }
    if (sigil_eq(result, sym_exit)) {
        return 0;
    }

    return 0;
}

SIGIL_EXPORT
int sigil_web_eval(const char *code)
{
    if (!g_vm) {
        fprintf(stderr, "Error: VM not initialized\n");
        return -1;
    }

    sigil_error_clear(g_vm);

    size_t code_len = strlen(code);
    size_t wrapped_len = code_len + 10;
    char *wrapped = malloc(wrapped_len);
    if (!wrapped) {
        fprintf(stderr, "Error: Out of memory\n");
        return -1;
    }

    snprintf(wrapped, wrapped_len, "(begin %s)", code);
    sigil_eval_string(g_vm, wrapped);
    free(wrapped);
    fflush(stdout);

    const char *err = sigil_error_message(g_vm);
    if (err) {
        fprintf(stderr, "Error: %s\n", err);
        fflush(stderr);
        return -1;
    }

    return 0;
}

SIGIL_EXPORT
int sigil_web_input(const char *input)
{
    if (!g_vm) {
        fprintf(stderr, "Error: VM not initialized\n");
        return -1;
    }

    sigil_error_clear(g_vm);

    size_t input_len = strlen(input);
    size_t escaped_len = 0;
    for (size_t i = 0; i < input_len; i += 1) {
        escaped_len += (input[i] == '"' || input[i] == '\\') ? 2 : 1;
    }

    char *escaped = malloc(escaped_len + 1);
    if (!escaped) {
        fprintf(stderr, "Error: Out of memory\n");
        return -1;
    }

    size_t j = 0;
    for (size_t i = 0; i < input_len; i += 1) {
        if (input[i] == '"' || input[i] == '\\') {
            escaped[j++] = '\\';
        }
        escaped[j++] = input[i];
    }
    escaped[j] = '\0';

    size_t call_len = 20 + escaped_len + 3;
    char *call = malloc(call_len);
    if (!call) {
        free(escaped);
        fprintf(stderr, "Error: Out of memory\n");
        return -1;
    }

    snprintf(call, call_len, "(web-input-resume \"%s\")", escaped);
    free(escaped);

    Value result = sigil_eval_string(g_vm, call);
    free(call);
    fflush(stdout);

    const char *err = sigil_error_message(g_vm);
    if (err) {
        fprintf(stderr, "Error: %s\n", err);
        fflush(stderr);
        return -1;
    }

    if (sigil_eq(result, sym_waiting)) {
        return 1;
    }
    if (sigil_eq(result, sym_exit)) {
        return 0;
    }

    return -1;
}

int main(int argc, char *argv[])
{
    (void)argc;
    (void)argv;

    if (sigil_web_init() != 0) {
        return 1;
    }

    return sigil_web_start() < 0 ? 1 : 0;
}
