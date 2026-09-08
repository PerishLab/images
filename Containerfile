ARG RUST_IMAGE=docker.io/library/rust:1.97.0-bookworm@sha256:b5a086f64ffecaa4e283063184770107915756739598173e1f5712d6b34b84d0
ARG AWS_IMAGE=public.ecr.aws/aws-cli/aws-cli:2.35.20@sha256:f311cee20d7a79db2fa5d97ee719e8cc1c1c32ecbb3230c4b4046af860862dfe
ARG NODE_IMAGE=docker.io/library/node:24.18.0-bookworm-slim@sha256:d45d78e7929b46875bbd4e29bea672d5bc48186c6c3588306521c815e78352d6
ARG DOCKER_IMAGE=docker.io/library/docker:29.6.1-cli@sha256:a011361b7e7dbf51ba0db930a7b746a0bb80935ac1b2f5d892a989025c80fab6
ARG HELM_VERSION=v4.2.4
ARG HELM_SHA256=c306b46f719b0a4da32d0f78ee21bf90ce8d602f15b22ab753f0674d1670a7f3

FROM ${RUST_IMAGE} AS rust

RUN rustup component add clippy rustfmt \
    && cargo install --locked --version 0.16.0 --no-default-features sccache

FROM ${AWS_IMAGE} AS aws

FROM ${DOCKER_IMAGE} AS docker

FROM ${NODE_IMAGE}

LABEL org.opencontainers.image.source="https://git.perish.top/PerishFire/images"
LABEL org.opencontainers.image.description="Perish Forge job image"

ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin \
    RUSTC_WRAPPER=sccache \
    SCCACHE_DIR=/sccache \
    CARGO_INCREMENTAL=0

COPY --from=rust /usr/local/cargo /usr/local/cargo
COPY --from=rust /usr/local/rustup /usr/local/rustup
COPY --from=aws /usr/local/aws-cli /usr/local/aws-cli
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/libexec/docker/cli-plugins/docker-buildx

ARG HELM_VERSION
ARG HELM_SHA256
ARG PNPM_VERSION=11.13.0
ARG PNPM_SHA256=2c15f7b6ab256642f4d01687a2b01e07714d835d05d29ba045bdbde59b17bb4f
ARG REGCTL_VERSION=v0.11.6
ARG REGCTL_SHA256=8e0e62a497fcdb8048d18aa927a139613176ba0531f412bc541044e28f9856bd

RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws \
    && apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update \
    && apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        jq \
        libssl-dev \
        openssh-client \
        pkg-config \
        unzip \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && helm=$(mktemp) \
    && curl --fail --silent --show-error --location --retry 3 \
        --output "$helm" \
        "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    && printf '%s  %s\n' "$HELM_SHA256" "$helm" | sha256sum --check --status \
    && tar --extract --gzip --file "$helm" --directory /usr/local/bin \
        --strip-components 1 linux-amd64/helm \
    && rm -f "$helm" \
    && pnpm=$(mktemp) \
    && curl --fail --silent --show-error --location --retry 3 \
        --output "$pnpm" \
        "https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/pnpm-linux-x64.tar.gz" \
    && printf '%s  %s\n' "$PNPM_SHA256" "$pnpm" | sha256sum --check --status \
    && mkdir /opt/pnpm \
    && tar --extract --gzip --file "$pnpm" --directory /opt/pnpm \
    && ln -s /opt/pnpm/pnpm /usr/local/bin/pnpm \
    && rm -f "$pnpm" \
    && curl --fail --silent --show-error --location --retry 3 \
        --output /usr/local/bin/regctl \
        "https://github.com/regclient/regclient/releases/download/${REGCTL_VERSION}/regctl-linux-amd64" \
    && printf '%s  %s\n' "$REGCTL_SHA256" /usr/local/bin/regctl | sha256sum --check --status \
    && chmod 755 /usr/local/bin/regctl \
    && mkdir /sccache \
    && rustc --version \
    && cargo --version \
    && rustfmt --version \
    && cargo clippy --version \
    && sccache --version \
    && node --version \
    && test "$(pnpm --version)" = "$PNPM_VERSION" \
    && aws --version \
    && jq --version \
    && docker --version \
    && docker buildx version \
    && test "$(regctl version --format '{{.VCSTag}}')" = "$REGCTL_VERSION" \
    && helm version \
    && helm package --help >/dev/null \
    && helm push --help >/dev/null \
    && test "$(rustc --version | cut -d ' ' -f 2)" = 1.97.0 \
    && test "$(node --version)" = v24.18.0 \
    && aws s3api put-object --generate-cli-skeleton input | jq -e 'has("IfNoneMatch") and has("IfMatch")'

RUN printf 'fn main(){print!("forge");}' >/tmp/forge.rs \
    && rustc /tmp/forge.rs -o /tmp/forge \
    && test "$(node -e 'process.stdout.write(require("node:child_process").execFileSync("/tmp/forge"))')" = forge \
    && rm -f /tmp/forge.rs /tmp/forge
