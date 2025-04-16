FROM debian:bookworm-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    patch \
    ca-certificates \
    python3 \
    golang-go && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY . .

RUN git submodule update --init

RUN cmake -B build -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/app/dist
RUN cmake --build ./build
RUN cmake --install ./build

FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/dist /app

ENV PATH="/app/bin:${PATH}"
ENV LD_LIBRARY_PATH="/app/lib"

EXPOSE 4000

CMD ["kad", "--host=0.0.0.0"]
