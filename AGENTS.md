# Agents

Images owns the content of the single Forge job image in `Containerfile`.
Its purpose is to supply the adopted shared job tools, not to register runners,
deploy appliances, configure a daemon, or introduce a custom executable.

Every base image is public and digest-pinned. The image carries no private CA,
credential, appliance route, dependency mirror, cluster, or runner lifecycle
logic. Docker, Buildx, regctl and Helm are clients; execution authority and
endpoints belong to the invoking environment.

Rust, Node, independent pnpm, Python, common Unix build tools, sccache, AWS CLI and the
projection clients form one adopted tool environment. Do not split it into
language-labelled images without distinct adopted job contracts. Corepack is
not part of its bootstrap or consumption contract.

Tool versions follow Plumb's locked Depot baseline. A newer base-image tag is
not authority to advance that baseline; the final image proves the exact
adopted compiler, package builder and toolchain manager before publication.

Python 3.11 or newer with its standard library and system TLS trust is a shared
workflow control capability. The image proves TOML, compression and TLS support
at build time; jobs consume the digest-pinned runtime without installing it.
Product-specific planning and publication behavior remain in Plumb.

Plumb's locked Depot profile owns repository governance and the release graph.
Plumb owns the workflow, version line, marker, immutable OCI publication and
explicit local recovery. This repository owns no workflow or Bake graph.
Build-time checks in the image recipe prove its tool and mixed-language
capabilities; successful publication still requires anonymous OCI readback.

`git.perish.top/PerishFire/images` is canonical source and
`git.perish.top/perishfire/images/forge` is canonical OCI authority.
GitHub is a one-way source mirror, not a release or recovery control plane.
Do not execute untrusted pull-request builds against a host Docker socket.
