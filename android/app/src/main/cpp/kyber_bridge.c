#include <stdint.h>
#include "kem.h"

// Macro to handle cross-compiler visibility and prevent symbol stripping
#if defined(_WIN32) || defined(__CYGWIN__)
#define FFI_EXPORT __declspec(dllexport)
#else
#if __GNUC__ >= 4
#define FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#else
#define FFI_EXPORT
#endif
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    FFI_EXPORT int32_t kyber512_keypair(uint8_t *pk, uint8_t *sk)
    {
        return crypto_kem_keypair(pk, sk);
    }

    FFI_EXPORT int32_t kyber512_encaps(uint8_t *ct, uint8_t *ss, const uint8_t *pk)
    {
        return crypto_kem_enc(ct, ss, pk);
    }

    FFI_EXPORT int32_t kyber512_decaps(uint8_t *ss, const uint8_t *ct, const uint8_t *sk)
    {
        return crypto_kem_dec(ss, ct, sk);
    }

#ifdef __cplusplus
}
#endif