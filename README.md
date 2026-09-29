# XCP-hl documentation preview

This repository is a deployment shell for [xcp-hl#60](https://github.com/Vagrantin/xcp-hl/issues/60).
The preview is currently served at <https://xcp-hl.net/>. Production remains
<https://vagrantin.github.io/xcp-hl/> until the migration is approved.

## Source and release data

`.github/workflows/pages.yml` checks out **Vagrantin/xcp-hl**, using the
`xcp_hl_ref` workflow input (default: `claude/gracious-ride-99qg08`). It builds
that checkout’s `site/` and never writes back to the source repository.
The old `site/`, `docs/` and `xoa-hl/` trees in **this** repository are legacy
snapshots and are ignored by the preview build. Do not copy new source into them.

A second read-only checkout gets `docs/_data/` from current **xcp-hl/main**.
The workflow logs the documentation source SHA and the release-data SHA separately.
This prevents the ISO badge and download links from remaining pinned to an old
migration branch’s release snapshot. Changes to curated Roadmap/Known limitations
still require source edits, as agreed in #109.

## Preview a candidate

Run **Deploy preview Pages (from xcp-hl branch)** in Actions and provide the
exact candidate SHA in `xcp_hl_ref`. The daily schedule rebuilds the default ref;
change that default deliberately after accepting a new source branch. For the
production-readiness candidate, use the reviewed SHA from the
`codex/docs-production-readiness` branch in `Vagrantin/xcp-hl`.

Hugo receives the actual Pages URL from `actions/configure-pages`. It supports
both the custom-domain root and a GitHub project subpath. The job validates
translation structure, URL collisions, language switching and asset locality;
newer source refs also validate internal links, anchors, language alternates and
legacy Jekyll URLs. The site is built first, then the placeholder repo is added
and both are uploaded in one Pages artifact.

## Limits of this preview

`repo/8.3/x86_64/repodata/repomd.xml` is a **placeholder**, not a real package
repository. This workflow proves that two directory trees coexist; it does not
prove GPG signatures, package retrieval or yum compatibility. Never configure an
installed host to use this placeholder repository.

The production switch is owned by `Vagrantin/xcp-hl/.github/workflows/pages.yml`.
Follow the candidate’s `site/CUTOVER.md` for the signed-repository rehearsal,
real XCP-ng yum acceptance, production approval and rollback. Do not move the
custom domain or change installed repository URLs as part of a preview refresh.
