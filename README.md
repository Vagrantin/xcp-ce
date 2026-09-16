# xcp-ce

> **This repository is currently being used as a staging ground.**
>
> It publishes the Hugo + Hextra documentation site proposed in
> [Vagrantin/xcp-hl#60](https://github.com/Vagrantin/xcp-hl/issues/60) to
> <https://vagrantin.github.io/xcp-ce/>, so the new delivery can be validated
> end to end before cutting over
> [xcp-hl's production Pages](https://vagrantin.github.io/xcp-hl/).
>
> The original Jekyll site under `docs/` is untouched — it is simply no longer
> published. Reverting the commit that repointed `.github/workflows/pages.yml`
> restores the old delivery exactly as it was.

## What the preview validates

`.github/workflows/pages.yml` deliberately mirrors the *shape* of xcp-hl's own
`pages.yml`, so what runs here is what will run there at cutover:

1. the site is built into `../_site` **first**, because the generator cleans its
   destination directory;
2. the yum repository tree is staged into `_site` **afterwards**;
3. one artifact, one deployment.

It then asserts both trees survived in one `_site`. That coexistence is the
load-bearing constraint on the whole migration — a Pages deploy replaces the
entire site, so the docs and the signed `xcp-hl-base` repository have to come out
of a single build — and it is the part most likely to break quietly.

It also asserts that every script, stylesheet and image is served from the site
itself, so a build-time fetch from a CDN cannot creep back in.

## What it does NOT validate

- **Signed repository metadata.** This repository has no releases and no GPG
  secrets, so the staged `repo/8.3/x86_64/` tree is a placeholder that only
  proves the Hugo build does not delete it. Verifying `repodata/repomd.xml`
  against a real `yum` run stays a Phase 5 acceptance test in `xcp-hl` itself,
  where `repo_gpgcheck=1` on every installed host makes it matter.
- **The production URL.** The baseurl here is `/xcp-ce/`, not `/xcp-hl/`. Hugo
  takes it from `actions/configure-pages`, so the site source stays
  byte-identical to the copy in `xcp-hl` and nothing needs editing to move
  between them.
- **Live release-matrix data.** `docs/_data/*.yml` here is a one-time
  snapshot copied over alongside `site/`, not kept current by
  `xcp-build-agent` the way `xcp-hl`'s own copy is — this repo has no such
  automation. The release matrix will drift stale; that's fine for what
  this rehearsal is for (proving the data-driven table mechanism works at
  all), not for reading current release info.

## What it now covers

All three languages — English, French, Japanese — are migrated
(`Vagrantin/xcp-hl#60` phases 1–3), each linked via the language switcher
(globe icon, top right) to the same page in the other two.

## Keeping the site in sync

`site/` is a straight copy of `site/` on the `claude/gracious-ride-99qg08` branch
of `Vagrantin/xcp-hl`, and `docs/_data/*.yml` here is a one-time copy of the
same path there (see **What it does NOT validate** above):

```bash
rm -rf site && cp -a ../xcp-hl/site site
rm -rf site/public site/resources site/data site/.hugo_build.lock
cp ../xcp-hl/docs/_data/*.yml docs/_data/
```

Build it locally with Hugo extended ≥ 0.146 and Go — see
[`site/README.md`](site/README.md).
