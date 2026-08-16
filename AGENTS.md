# Agents

This repository is the Forgejo-native OCI source closure for Perish images. It
authors image content and the workflows that prove and publish that content; it
never owns runner activation, appliance deployment, or a custom executable.

## Shape

- `Containerfile.forge` defines the single published Forge job image. Do not
  split it into language-labelled variants without distinct adopted job contracts.
- `docker-bake.hcl` is the complete build graph and image naming contract.
- `.forgejo/workflows` contains only native guard and publication.
- Do not add a CLI, task runner, generated build context, reusable action, or
  runner control logic.

## Closure

- Every base image is a public OCI reference pinned by digest.
- Images contain no private CA, credential, appliance route, or dependency
  mirror configuration.
- `mirror.perish.lan` is never an input or publication authority.
- `git.perish.top/PerishFire/images` is canonical source and
  `git.perish.top/perishfire/images/*` is canonical OCI authority.
- GitHub is a one-way source mirror only. It owns no workflow, package,
  credential, release, or recovery control plane.
- Deno compatibility and Forgejo Runner lifecycle are outside this repository.
- The Forge image carries exact Rust and Node toolchains, common Unix build
  tools, sccache, AWS CLI, jq, the Docker client, and Helm. It does not carry
  Go, Python, Deno, mcli, age, linker policy, private trust, or runner logic.
- The Docker client and Helm are clients only. The image carries no daemon and
  no cluster, so a job that projects an image or a chart supplies its own
  endpoint and credentials. Carrying them is what lets a release lane project
  onto those media at all; withholding them made every such projection
  undeclarable rather than merely unconfigured.
- Release identity is an immutable image digest with anonymous public readback.

## Workflow

- Initial jobs target the existing `docker` runner and its Docker execution
  surface. Actions owns that runner's registration and lifetime.
- Guard execution is credential-free and image builds only consume public
  upstream images.
- Publication is manual, writes only to the Forgejo OCI namespace, logs out
  after pushing, and then proves anonymous readback.
- Forgejo self-bootstrap after loss of its usable runner or image closure is a
  deferred cold-start profile. Do not claim it from the initial workflows.
- Do not execute untrusted pull-request image builds against a host Docker socket.

## Operating

- Never commit on `main`; work on a branch and land through the repository guard.
- Run `plumb doctor .`, `ectropy .`, `docker buildx bake --print`, and the default
  Bake group before landing.
- Keep accelerators, caches, labels, tokens, and deployment policy in Actions or
  Hardrig according to their existing ownership boundaries.
