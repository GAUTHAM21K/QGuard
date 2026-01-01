cmake_minimum_required(VERSION 3.18.1)

project("kyber")

# Create the shared library
add_library(kyber SHARED
    api.h
    cbd.c
    cbd.h
    fips202.c
    fips202.h
    indcpa.c
    indcpa.h
    kem.c
    kem.h
    kyber_bridge.c
    ntt.c
    ntt.h
    params.h
    poly.c
    poly.h
    polyvec.c
    polyvec.h
    randombytes.c
    randombytes.h
    reduce.c
    reduce.h
    symmetric-shake.c
    symmetric.h
    verify.c
    verify.h
)

# Set Kyber to 512-bit security (K=2) to match Dart expectations
target_compile_definitions(kyber PRIVATE KYBER_K=2)

# Link against Android log library
find_library(log-lib log)
target_link_libraries(kyber ${log-lib})

# Set C standard
set_property(TARGET kyber PROPERTY C_STANDARD 99)