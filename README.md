# XCP-hl documentation deployment

This repository hosts the new documentation preview, currently at
https://xcp-hl.net/. The documentation source is committed in
[Vagrantin/xcp-hl](https://github.com/Vagrantin/xcp-hl), not here.

## Deployment

The `Deploy preview Pages (from xcp-hl branch)` workflow checks out a supplied
`xcp_hl_ref` from `Vagrantin/xcp-hl`. The scheduled default is
`claude/gracious-ride-99qg08`. Use a reviewed branch, tag or commit that includes
`site/scripts/build_docs.sh` and the XOA-HL manual foundation from issue #189.
The workflow uses the actual Pages base URL, builds all three languages, runs the
source repository's validation pipeline in `XOA_PUBLICATION_MODE=reviewed`, and
publishes one documentation artifact. A changed English source or translation
invalidates its revision-bound review record and stops the deployment until the
affected French/Japanese pages are reviewed again.

Release matrices and generated changelog data are staged by the source build
script from `Vagrantin/xcp-hl` `main`. `RELEASE_DATA_REF=local` is reserved for
source-checkout testing; the scheduled deployment uses the current main data.

This deployment does not stage RPMs, `.repo` files, repository metadata or fake
package-repository placeholders. Existing package publishing and the old official
documentation remain in `xcp-hl` outside this preview change. No signing secrets or
combined documentation/package cutover are required here.

The legacy `docs/`, `site/` and `xoa-hl/` trees still present here are ignored by
the deployment workflow. Do not edit them to change the published manual.

Issues and documentation changes are tracked in
[Vagrantin/xcp-hl#189](https://github.com/Vagrantin/xcp-hl/issues/189).
