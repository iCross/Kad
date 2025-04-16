
FROM debian:bookworm AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    patch \
    ca-certificates \
    python3 \
    golang-go \
    xz-utils \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY .git .git
COPY .gitmodules .gitmodules

RUN git submodule update --init --recursive

COPY . .

RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_INSTALL_PREFIX=/app/dist \
    -DGO_EXECUTABLE=$(which go) \
    -DPERL_EXECUTABLE='/usr/bin/perl' \
    .

RUN cmake --build ./build --parallel $(nproc)

RUN cmake --install ./build

FROM debian:bookworm-slim AS final

RUN groupadd --gid 1001 kad && \
    useradd --uid 1001 --gid 1001 --shell /bin/false --create-home kad

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder --chown=kad:kad /app/dist /app

ENV LD_LIBRARY_PATH=/app/lib

RUN chown -R kad:kad /app && \
    chmod -R u=rwX,go=rX /app && \
    find /app/bin -type f -exec chmod +x {} \;

USER kad

EXPOSE 4000

ENTRYPOINT ["/app/bin/kad"]

CMD ["--host=0.0.0.0"]
