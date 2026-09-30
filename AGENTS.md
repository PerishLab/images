# Images

Read the canonical [PerishLab delivery governance](https://github.com/PerishLab/.github/blob/main/GOVERNANCE.md)
at work start and again before delivery or Issue closure. That document owns
organization-wide Issue, pull-request and acceptance policy; this file keeps
repository-specific constraints without copying that policy.

Images owns the contents of the one shared perish.code Guard execution image.
GitHub is the canonical source and `ghcr.io/perishlab/images` is the public OCI
authority. Wharf distributes the tracked recipe; Plumb owns Guard policy,
prerequisite resolution and execution-world evidence; `PerishLab/.github` owns
organization workflow adoption. Wharf's distribution record is read through
`https://releases.images.perish.uk`; it is release evidence, not a second image
authority.

The image supplies adopted tools, not repository policy. It owns no runner,
registration, daemon, host lifecycle, credential, private CA, dependency mirror
or endpoint. Docker, Buildx, regctl, Helm and AWS are clients whose authority is
provided by the invoking environment.

Rust, Node, independent pnpm, Python, common Unix build tools, sccache and the
projection clients form one environment. Do not split them into language images
without distinct adopted job contracts. Corepack is not part of the bootstrap or
consumption contract.

Every base and downloaded tool is public and pinned by digest or checksum. The
recipe proves exact adopted versions and mixed-language capability at build time.
It must not export cache, compiler or build-policy variables that can shadow the
repository world Plumb records.

Publication is an attachment-only Wharf release from the committed source tree.
It succeeds only after anonymous digest readback. A published digest is immutable;
rotation and retirement begin from an Issue and publish a new marker and digest.
