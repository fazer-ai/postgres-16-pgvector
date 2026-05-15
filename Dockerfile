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
 && ln -s /usr/bin/llvm-lto /usr/lib/llvm19/bin/llvm-lto

ENV CC=clang

RUN git clone --depth 1 https://github.com/pgvector/pgvector.git \
 && cd pgvector \
 && make \
 && make install \
 && cd .. \
 && rm -rf pgvector

COPY docker-entrypoint-initdb.d/01-create-vector.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/01-create-vector.sh
