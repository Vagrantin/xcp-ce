---
layout: default
title: Developers
nav_order: 4
has_children: true
---

# Developer Documentation
{: .no_toc }

Everything you need to understand, build, and contribute to XCP-ng CE.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Repository overview

XCP-ng CE is split across three functional repositories plus this
documentation/release repo.

```
Vagrantin/xcp-ce          ← docs (this site) + ISO GitHub Releases
      │
      ├── Vagrantin/xolite-ce       ← XO Lite patch + RPM build
      │         │ publishes signed RPM as GitHub Release artifact
      │         ▼
      └── Vagrantin/xcp-ng-ce-iso   ← ISO assembly
                │ downloads RPM from xolite-ce, assembles ISO
                │
      Vagrantin/xoa-proxy           ← Rust HTTP proxy (bundled in ISO)
```

Each repo has its own GitHub Actions pipeline. They are **loosely coupled**:
`xolite-ce` publishes versioned RPM artifacts that `xcp-ng-ce-iso` fetches
by release tag. Neither repo needs to be checked out together for normal
builds.

---

## Tech stack

| Layer | Technology |
|---|---|
| Hypervisor base | XCP-ng 8.3 (Xen 4.17, Linux 4.19 Dom0) |
| XO Lite UI | Vue 3 · TypeScript · Vite · Pinia (`@xen-orchestra/lite`) |
| XO Lite build | Yarn (Corepack) · `yarn build:xo-lite` |
| RPM packaging | `rpmbuild`, `rpmsign`, `createrepo_c` |
| ISO assembly | `create-install-image` (XCP-ng toolchain, master branch) |
| ISO tooling | `mksquashfs`, `xorriso`, `isohybrid`, `implantisomd5` |
| Build environment | Docker (`xcp-ng-build-env:8.3`) |
| Proxy server | Rust · `hyper` · `tokio` · `tokio_util::io::ReaderStream` |
| CI/CD | GitHub Actions (free tier) |
| Signing | GPG 4096-bit RSA (`RPM-GPG-KEY-xcp-ng-ce`) |

---

## Build pipeline — end to end

```
1. xolite-ce CI (GitHub Actions)
   ├── Clone vatesfr/xen-orchestra at release tag
   ├── Apply patches/community-xoa-deploy.patch
   ├── yarn build:xo-lite
   ├── rpmbuild → xo-lite-community-<VERSION>.rpm
   ├── rpmsign (GPG_PRIVATE_KEY secret)
   └── Publish RPM as GitHub Release asset

2. xcp-ng-ce-iso CI (GitHub Actions)
   ├── Download signed RPM from xolite-ce release
   ├── Build xoa-proxy (Rust, cross-compiled for Dom0)
   ├── Set up community-repo/x86_64/ with createrepo_c
   ├── Run create-installimg.sh (root) — builds install.img (SquashFS)
   ├── Run create-iso.sh (non-root) — assembles ISO
   ├── isohybrid --uefi (hybrid MBR/GPT stamp)
   ├── implantisomd5
   └── Publish ISO to Vagrantin/xcp-ce GitHub Release
```

---

## Key design decisions

### Two-repo strategy
Separating the RPM build from the ISO build keeps concerns clean: `xolite-ce`
can be iterated on (UI patch, packaging) without touching the ISO toolchain,
and vice versa. The RPM artifact is the published contract between the two.

### Patch at source level
The XO Lite patch is applied to the Vue/TypeScript **source** of
`DeployXoaView.vue`, not to the compiled output. When upstream refactors that
file, the build fails at patch-apply time rather than silently shipping broken
code. Updating for a new upstream version is a single `git format-patch`
operation.

### SquashFS install.img
`install.img` is a **SquashFS** archive, not a cpio archive. Using `cpio`
produces a broken image that causes a kernel panic at boot. Always use
`unsquashfs` / `mksquashfs -comp xz -b 131072`.

### isohybrid post-processing
`xorriso` flags alone do not stamp the hybrid MBR/GPT partition table needed
for physical hardware boot. `isohybrid --uefi` must be run as a post-processing
step. Verify with `fdisk -l` and `xorriso -report_el_torito`.

### RPM DB scope
`rpm --import` inside a Docker container writes to the **container's** RPM DB,
not to the chroot installroot. Use `rpm --root=$ROOTFS --import` explicitly.

### TMPDIR / HOME in Docker
`create-install-image`'s `misc.sh` unconditionally reassigns `TMPDIR` at
runtime, overriding any `-e TMPDIR=` passed to `docker run`. The only reliable
way to control it is with `ENV TMPDIR=/tmp` in the `Dockerfile`. Similarly,
`HOME` must be set via `-e HOME=/tmp` for the non-root `create-iso.sh` step.

---

## GPG signing

The community keypair is a 4096-bit RSA key stored as GitHub Actions secrets:

| Secret | Content |
|---|---|
| `GPG_PRIVATE_KEY` | ASCII-armored private key |
| `GPG_PASSPHRASE` | Key passphrase |

The corresponding public key (`RPM-GPG-KEY-xcp-ng-ce`) is committed to
`xolite-ce` and overlaid into the ISO's installer keyring.

> **Current state (Path A):** the installer uses `gpgcheck=false` as a boot
> parameter. Path B (injecting the key into the installer RPM DB) is tracked
> as a GitHub Issue in `xcp-ng-ce-iso`.

---

## Detailed component docs

| Page | Description |
|---|---|
| [xoa-proxy](xoa-proxy) | Rust HTTP/gzip proxy for XVA delivery |
| [xolite-ce](xolite-ce) | XO Lite patch, RPM spec, build pipeline |
| [xcp-ng-ce-iso](xcp-ng-ce-iso) | ISO assembly, toolchain, CI workflow |
