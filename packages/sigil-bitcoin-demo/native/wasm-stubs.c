#include "sigil-internal.h"
#include "cps-emit-native.h"

#include <stdbool.h>

extern Value sigil_apply_list(SigilVM *vm, Value proc, Value args);

SigilShadowStack sigil_native_shadow_stack;
bool sigil_native_exception_unwinding = false;
Value sigil_native_exception_result = SIGIL_UNDEFINED;
int sigil_native_trampoline_depth = 0;

Value sigil_native_bridge_call(SigilVM *vm, Value proc, Value *args, int nargs)
{
    if (sigil_is_ptr(proc)) {
        SigilObjHeader *obj = (SigilObjHeader *)sigil_as_ptr(proc);
        if (obj->type == SIGIL_OBJ_NATIVE_CLOSURE) {
            sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                            "native codegen closures are not available in WASM");
            return SIGIL_UNDEFINED;
        }
    }

    switch (nargs) {
    case 0:
        return sigil_apply0(vm, proc);
    case 1:
        return sigil_apply1(vm, proc, args[0]);
    case 2:
        return sigil_apply2(vm, proc, args[0], args[1]);
    case 3:
        return sigil_apply3(vm, proc, args[0], args[1], args[2]);
    default: {
        Value list = SIGIL_EMPTY;
        for (int i = nargs - 1; i >= 0; i--) {
            list = sigil_cons(vm, args[i], list);
        }
        return sigil_apply_list(vm, proc, list);
    }
    }
}

int sigil_native_shadow_stack_depth(void)
{
    return sigil_native_shadow_stack.depth;
}

bool sigil_native_in_fiber(void)
{
    return false;
}

int sigil_native_fiber_stack_count(void)
{
    return 0;
}

void sigil_native_fiber_stack_bounds(int idx, void **lo, void **hi)
{
    (void)idx;
    *lo = NULL;
    *hi = NULL;
}

void sigil_native_capture_gc_mark(SigilVM *vm, void (*mark_fn)(SigilVM *, Value))
{
    (void)vm;
    (void)mark_fn;
}

int sigil_native_max_suspended_frame_count(SigilVM *vm)
{
    return vm->frame_count;
}

void sigil_native_mark_fiber_bc_frames(
    SigilVM *vm,
    void (*mark_obj)(SigilVM *, SigilObjHeader *),
    void (*mark_value)(SigilVM *, Value))
{
    (void)vm;
    (void)mark_obj;
    (void)mark_value;
}

Value sigil_native_resume_fiber(SigilVM *vm, int fiber_idx, Value value)
{
    (void)fiber_idx;
    sigil__vm_error(vm, SIGIL_ERR_RUNTIME,
                    "native fibers are not available in WASM");
    return value;
}
