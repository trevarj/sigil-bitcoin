#pragma once

/* WASI has no POSIX sockets. Keep sigil-crypto's normal mbedTLS profile, but
   remove the networking module for browser-only Bitcoin tooling. */
#include_next "sigil_mbedtls_config.h"

#undef MBEDTLS_NET_C
#undef MBEDTLS_HAVE_TIME
#undef MBEDTLS_HAVE_TIME_DATE

#define MBEDTLS_NO_PLATFORM_ENTROPY
