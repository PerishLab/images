ARG RUST_IMAGE=docker.io/library/rust:1.96.1-trixie@sha256:1f0dbad1df66647807e6952d1db85d0b2bda7606cb2139d82517e4f009967376
ARG AWS_IMAGE=public.ecr.aws/aws-cli/aws-cli:2.35.20@sha256:f311cee20d7a79db2fa5d97ee719e8cc1c1c32ecbb3230c4b4046af860862dfe
ARG NODE_IMAGE=docker.io/library/node:24.18.0-trixie-slim@sha256:ae91dcc111a68c9d2d81ff2a17bda61be126426176fde6fe7d08ab13b7f50573
ARG DOCKER_IMAGE=docker.io/library/docker:29.6.1-cli@sha256:a011361b7e7dbf51ba0db930a7b746a0bb80935ac1b2f5d892a989025c80fab6
ARG HELM_VERSION=v4.2.4
ARG HELM_SHA256=c306b46f719b0a4da32d0f78ee21bf90ce8d602f15b22ab753f0674d1670a7f3

FROM ${RUST_IMAGE} AS rust

RUN curl --fail --silent --show-error --location --retry 3 \
        --output /tmp/rustup-init \
        https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-unknown-linux-gnu/rustup-init \
    && printf '%s  %s\n' dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71 /tmp/rustup-init | sha256sum --check --status \
    && chmod 755 /tmp/rustup-init \
    && /tmp/rustup-init -y --no-modify-path --default-toolchain none \
    && test "$(rustup --version)" = 'rustup 1.29.1 (d95a37b6a 2026-08-13)' \
    && rm -f /tmp/rustup-init \
    && rustup component add clippy rustfmt \
    && cargo install --locked --version 0.16.0 --no-default-features sccache

FROM ${AWS_IMAGE} AS aws

FROM ${DOCKER_IMAGE} AS docker

FROM ${NODE_IMAGE}

LABEL org.opencontainers.image.source="https://github.com/PerishLab/images"
LABEL org.opencontainers.image.description="Perish Guard execution image"

ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin

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
    && test "$(rustup --version)" = 'rustup 1.29.1 (d95a37b6a 2026-08-13)' \
    && test "$(rustc --version)" = 'rustc 1.96.1 (31fca3adb 2026-06-26)' \
    && test "$(cargo --version)" = 'cargo 1.96.1 (356927216 2026-06-26)' \
    && test "$(node --version)" = v24.18.0 \
    && test "$(getconf GNU_LIBC_VERSION)" = 'glibc 2.41' \
    && aws s3api put-object --generate-cli-skeleton input | jq -e 'has("IfNoneMatch") and has("IfMatch")'

RUN control_home=$(mktemp -d) \
    && curl --fail --silent --show-error --location --retry 3 \
        --output /tmp/manage-plumb.sh \
        https://releases.plumb.perish.uk/manage.sh \
    && HOME="$control_home" PLUMB_CHANNEL=stable PLUMB_VERSION= \
        sh /tmp/manage-plumb.sh install \
    && "$control_home/.local/bin/plumb" --version \
    && test "$(rustup default)" = "$("$control_home/.local/bin/plumb" metadata rust.version)-x86_64-unknown-linux-gnu (default)" \
    && test "$(rustc --version | cut -d ' ' -f 2)" = "$("$control_home/.local/bin/plumb" metadata rust.version)" \
    && test "$(node --version)" = "v$("$control_home/.local/bin/plumb" metadata node.version)" \
    && test "$(pnpm --version)" = "$("$control_home/.local/bin/plumb" metadata pnpm.version)" \
    && curl --fail --silent --show-error --location --retry 3 \
        --output /tmp/manage-ectropy.sh \
        https://releases.ectropy.perish.uk/manage.sh \
    && HOME="$control_home" ECTROPY_CHANNEL=stable ECTROPY_VERSION= \
        sh /tmp/manage-ectropy.sh install \
    && "$control_home/.local/bin/ectropy" --version \
    && rm -rf "$control_home" /tmp/manage-plumb.sh /tmp/manage-ectropy.sh

RUN printf 'fn main(){print!("images");}' >/tmp/probe.rs \
    && rustc /tmp/probe.rs -o /tmp/probe \
    && test "$(node -e 'process.stdout.write(require("node:child_process").execFileSync("/tmp/probe"))')" = images \
    && rm -f /tmp/probe.rs /tmp/probe

RUN apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update \
    && apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -c 'import gzip, hashlib, json, ssl, subprocess, sys, tarfile, tomllib, urllib.request, zipfile; assert sys.version_info >= (3, 11); assert tomllib.loads("ready = true")["ready"]; assert ssl.create_default_context().get_ca_certs(); assert gzip.decompress(gzip.compress(b"images")) == b"images"; print(sys.version)'

RUN test -x /usr/sbin/policy-rc.d \
    && policy_status=0 && /usr/sbin/policy-rc.d ssh start || policy_status=$?; \
    test "$policy_status" = 101 \
    && apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update \
    && ssh_version=$(dpkg-query -W -f='${Version}' openssh-client) \
    && DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 install -y --no-install-recommends "openssh-server=$ssh_version" \
    && /usr/sbin/update-rc.d -f ssh remove \
    && find /etc/systemd/system -type l \( -lname '*/ssh.service' -o -lname '*/ssh.socket' -o -lname '*/sshd-keygen.service' \) -delete \
    && truncate --size 0 /etc/machine-id \
    && rm -f /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub \
        /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key.pub \
        /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key.pub \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/sbin/sshd /usr/local/bin/sshd \
    && install -d -m 0755 /run/sshd \
    && test -z "$(find /etc/ssh -maxdepth 1 -name 'ssh_host_*' -print)" \
    && test ! -s /etc/machine-id \
    && test -z "$(find /etc/systemd/system -type l \( -lname '*/ssh.service' -o -lname '*/ssh.socket' -o -lname '*/sshd-keygen.service' \) -print)"

RUN --network=none python3 - <<'PY'
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

sshd = shutil.which("sshd")
assert sshd and os.path.isabs(sshd)
assert not list(Path("/etc/ssh").glob("ssh_host_*"))
assert not Path("/etc/machine-id").read_bytes()
user = "images-ssh-smoke"
subprocess.run(["/usr/sbin/useradd", "--no-create-home", "--shell", "/bin/sh", "--password", "x", user], check=True)
try:
    with tempfile.TemporaryDirectory(prefix="images-ssh-") as temporary:
        root = Path(temporary)
        root.chmod(0o755)
        host = root / "host"
        identity = root / "identity"
        for key in (host, identity):
            subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key)], check=True)
        authorized = root / "authorized_keys"
        authorized.write_bytes(identity.with_suffix(".pub").read_bytes())
        authorized.chmod(0o644)
        with socket.socket() as reservation:
            reservation.bind(("127.0.0.1", 0))
            port = reservation.getsockname()[1]
        config = root / "sshd_config"
        config.write_text("\n".join([
            "ListenAddress 127.0.0.1", f"Port {port}", f"HostKey {host}",
            f"PidFile {root / 'sshd.pid'}", f"AuthorizedKeysFile {authorized}",
            "PasswordAuthentication no", "KbdInteractiveAuthentication no",
            "PubkeyAuthentication yes", "UsePAM no", "StrictModes no",
            f"AllowUsers {user}", "AllowTcpForwarding no", "X11Forwarding no",
            "PermitTunnel no", "PermitUserEnvironment no", "LogLevel ERROR", "",
        ]))
        subprocess.run([sshd, "-t", "-f", str(config)], check=True)
        with (root / "sshd.log").open("w+") as log:
            server = subprocess.Popen([sshd, "-D", "-e", "-f", str(config)], stdout=log, stderr=log)
            try:
                for attempt in range(100):
                    assert server.poll() is None, "isolated sshd exited before accepting connections"
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                            break
                    except OSError:
                        time.sleep(0.05)
                else:
                    raise AssertionError("isolated sshd did not start within five seconds")
                result = subprocess.run([
                    "ssh", "-F", "/dev/null", "-i", str(identity), "-p", str(port),
                    "-o", "BatchMode=yes", "-o", "IdentitiesOnly=yes",
                    "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null",
                    "-o", "GlobalKnownHostsFile=/dev/null", "-o", "ConnectTimeout=5",
                    f"{user}@127.0.0.1", "printf images-ssh",
                ], check=True, capture_output=True, text=True, timeout=10)
                assert result.stdout == "images-ssh"
            finally:
                server.terminate()
                try:
                    server.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait(timeout=5)
            with socket.socket() as stopped:
                stopped.settimeout(1)
                assert stopped.connect_ex(("127.0.0.1", port)) != 0
        assert server.poll() is not None
    assert not root.exists()
finally:
    subprocess.run(["/usr/sbin/userdel", user], check=True)
assert not list(Path("/etc/ssh").glob("ssh_host_*"))
assert not Path("/etc/machine-id").read_bytes()
print("isolated OpenSSH startup, authentication and cleanup passed")
PY
