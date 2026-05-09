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
Vagrantin/xcp-ce          ← docs (this site)
      │
      ├── Vagrantin/xolite-ce       ← XO Lite patch + RPM build
      │         │ publishes signed RPM as GitHub Release artifact
      │         │ 
      ├─────────│───Vagrantin/xoa-proxy           ← Rust HTTP proxy + RPM build
      │         │        │  publishes signed RPM as GitHub Release artifact
      │         ▼        ▼
      └── Vagrantin/xcp-ng-ce-iso   ← ISO assembly + ISO GitHub Releases
                │ downloads RPM from xolite-ce and xoa-proxy, assembles ISO
                │
```

Each repo has its own GitHub Actions pipeline. They are **loosely coupled**:
`xolite-ce` and `xoa-proxy` publishes versioned RPM artifacts that `xcp-ng-ce-iso` fetches
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

2. xoa-proxy CI (GitHub Actions)
   ├── Install musl toolchain (musl-1.2.4, static libc)
   ├── Install Rust stable via rustup
   ├── Add x86_64-unknown-linux-musl target
   ├── cargo build --release --target x86_64-unknown-linux-musl
   ├── Prepare RPM sources (binary + systemd unit + logrotate config)
   ├── rpmbuild → xoa-proxy-<VERSION>.rpm
   ├── rpmsign (GPG_PRIVATE_KEY secret)
   └── Publish RPM as GitHub Release asset

3. xcp-ng-ce-iso CI (GitHub Actions)
   ├── Download signed RPM from xolite-ce release
   ├── Download signed RPM from xoa-proxy release
   ├── Set up community-repo/x86_64/ with createrepo_c
   ├── Run create-installimg.sh (root) — builds install.img (SquashFS)
   ├── Run create-iso.sh (non-root) — assembles ISO
   ├── isohybrid --uefi (hybrid MBR/GPT stamp)
   ├── implantisomd5
   └── Publish ISO to Vagrantin/xcp-ce GitHub Release
```

---

## Key design decisions

### Three-repo strategy
Separating each RPM build from the ISO assembly keeps concerns clean:
`xolite-ce` (UI patch, packaging) and `xoa-proxy` (Rust proxy, packaging)
can each be iterated on independently without touching the ISO toolchain,
and vice versa. Each publishes a versioned, signed RPM as a GitHub Release
artifact — that artifact is the published contract with `xcp-ng-ce-iso`,
which only consumes and build the ISO.

### Patch at source level
The XO Lite patch is applied to the Vue/TypeScript **source** of
`DeployXoaView.vue`, not to the compiled output.

---

## GPG signing

The community keypair is a 4096-bit RSA key stored as GitHub Actions secrets:

| Secret | Content |
|---|---|
| `GPG_PRIVATE_KEY` | ASCII-armored private key |
| `GPG_PASSPHRASE` | Key passphrase |

The corresponding public key (`RPM-GPG-KEY-xcp-ng-ce`) is committed to
`xolite-ce` and overlaid into the ISO's installer keyring.

---

## Detailed component

| Page | Description |
|---|---|
| [xoa-proxy](xoa-proxy) | Rust HTTP/gzip proxy for XVA delivery |
| [xolite-ce](xolite-ce) | XO Lite patch, RPM spec, build pipeline |
| [xcp-ng-ce-iso](xcp-ng-ce-iso) | ISO assembly, toolchain, CI workflow |
