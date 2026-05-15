FROM postgres:16-alpine

RUN apk update && apk add --no-cache \
    build-base \
    git \
    postgresql-dev \
    clang20 \
    llvm20-dev \
    llvm20-libs \
    llvm20-linker-tools

RUN ln -sf /usr/bin/clang-20   /usr/bin/clang \
 && ln -sf /usr/bin/clang++-20 /usr/bin/clang++ \
 && ln -s  /usr/bin/clang-20   /usr/bin/clang-19 \
 && ln -s  /usr/bin/clang++-20 /usr/bin/clang++-19 \
 && mkdir -p /usr/lib/llvm19/bin \
 && ln -s /usr/lib/llvm20/bin/llvm-lto /usr/lib/llvm19/bin/llvm-lto

ENV CC=clang

# pgvector's Makefile defaults OPTFLAGS to -march=native, which bakes the build
# host's full instruction set into the .so, including AVX-512 on the
# ubuntu-latest amd64 runner, or SVE on some arm64 runners. The resulting binary
# crashes with SIGILL on lower-baseline CPUs (DO Regular droplets, Hetzner
# shared, older bare metal). We override OPTFLAGS with a portable per-arch
# baseline that still keeps useful SIMD: amd64 -> x86-64-v3 (AVX2 + BMI2 + FMA,
# no AVX-512); arm64 -> armv8-a (NEON, mandatory in base ARMv8). TARGETARCH is
# set automatically by buildx for multi-arch builds.
# Ref: https://en.wikipedia.org/wiki/X86-64#Microarchitecture_levels
ARG TARGETARCH
RUN git clone --depth 1 https://github.com/pgvector/pgvector.git \
 && cd pgvector \
 && case "$TARGETARCH" in \
      amd64) OPTFLAGS="-march=x86-64-v3 -mtune=generic" ;; \
      arm64) OPTFLAGS="-march=armv8-a -mtune=generic" ;; \
      *)     OPTFLAGS="-mtune=generic" ;; \
    esac \
 && make OPTFLAGS="$OPTFLAGS" \
 && make install \
 && cd .. \
 && rm -rf pgvector

COPY docker-entrypoint-initdb.d/01-create-vector.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/01-create-vector.sh
