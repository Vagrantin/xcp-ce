---
layout: default
title: xolite-ce
parent: Developers
nav_order: 2
---

# xolite-ce
{: .no_toc }

Community patch for XO Lite and the RPM build pipeline.
{: .fs-6 .fw-300 }

**Repository:** [Vagrantin/xolite-ce](https://github.com/Vagrantin/xolite-ce)
· Language: TypeScript / Vue 3 (patch) · RPM spec · License: GPL-3.0

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## What is XO Lite?

XO Lite is the lightweight single-page management application that ships
bundled with every XCP-ng host. It runs entirely in the browser — served
directly from the host — and is implemented as a Vue 3 / TypeScript / Vite
SPA inside the `vatesfr/xen-orchestra` monorepo at
`packages/@xen-orchestra/lite`.

On a standard XCP-ng host, XO Lite includes a **"Deploy XOA"** screen
(`DeployXoaView.vue`) that calls home to Vates infrastructure to download and
import the commercial Xen Orchestra Appliance. XCP-ng CE replaces this
behaviour with a community-hosted deployment that requires no internet access
and no Vates account.

---

## The patch

The community change is expressed as a single **`git format-patch`** file:

```
xolite-ce/
└── patches/
    └── community-xoa-deploy.patch
```

The patch modifies `DeployXoaView.vue` only. It:

- Sets the XOA image URL to the community `xoa-proxy` endpoint.
- Marks the credential input fields as **read-only** using the `readonly`
  attribute on `<FormInput>` components (the same pattern used in
  `AppLogin.vue` upstream).
- Pre-fills credentials with the community XOA defaults
  (`admin@admin.net` / `admin` / SSH `xo` / `xopass`).
- Removes the Vates-specific metadata fetch and phone-home calls.

### Why patch at source level?

Patching the compiled/minified JS output would be fragile — any upstream
release would invalidate the patch. Patching the TypeScript source means:

- The build fails **loudly** if upstream refactors `DeployXoaView.vue` in a
  way that conflicts with the patch.
- Updating for a new XCP-ng release is a single `git format-patch` after
  rebasing the change onto the new upstream tag.
- The patch diff is human-readable and reviewable.

---

## Build pipeline

### Overview

```
1. Read XO_VERSION from the RPM in the upstream XCP-ng ISO
2. Clone vatesfr/xen-orchestra at the matching release tag
3. Apply patches/community-xoa-deploy.patch
4. Install dependencies with Yarn (Corepack)
5. Build XO Lite: yarn build:xo-lite
6. Assemble RPM source tarball
7. rpmbuild -ba SPECS/xo-lite-community.spec
8. rpmsign with community GPG key
9. Publish RPM as GitHub Release asset
```

### Step 1 — version detection

The target XO Lite version is read from the RPM already on the upstream
XCP-ng ISO, not hardcoded:

```bash
XO_VERSION=$(rpm -qp --qf '%{VERSION}' xo-lite-*.rpm)
```

This ensures the community RPM always matches the upstream version, making
it a drop-in replacement.

### Step 4 — Yarn build notes

XO Lite is part of the `vatesfr/xen-orchestra` monorepo. Its sibling
workspace `@xen-orchestra/web-core` must be compiled **before** Vite can
bundle XO Lite itself. The correct build invocation is:

```bash
# Must be run FIRST — compiles @xen-orchestra/web-core and other deps
yarn build:xo-lite
```

Running `vite build` directly or `yarn workspace @xen-orchestra/lite build`
without this step will fail with missing module errors.

### Step 6 — Tarball structure

The source tarball passed to `rpmbuild` has this layout:

```
xo-lite-{VERSION}/
├── dist/               ← compiled Vite output
├── CHANGELOG.md
├── LICENSE
└── xolite.html         ← renamed from scripts/xolite-loader.html
```

The `xolite.html` filename is required — this is the entry point served by
the XCP-ng host to load XO Lite in the browser.

### RPM spec

`SPECS/xo-lite-community.spec` defines:

- `Name: xo-lite-community`
- `Version: %{XO_VERSION}` (injected at build time)
- `Provides: xo-lite` (so it satisfies any dependency on the upstream package)
- `Conflicts: xo-lite` (prevents co-installation with the upstream RPM)
- File list: `dist/` contents + `xolite.html`

---

## Local development

### Prerequisites

- Node.js 18+ and Yarn (enabled via `corepack enable`)
- `rpmbuild` (`rpm-build` package on RHEL/CentOS/Fedora)
- `rpmsign` (`rpm-sign` package)
- GPG key imported in your keyring

### Workflow

```bash
# 1. Clone the repo
git clone https://github.com/Vagrantin/xolite-ce.git
cd xolite-ce

# 2. Clone upstream xen-orchestra at the target tag
XO_VERSION=<version>
git clone --depth 1 --branch v${XO_VERSION} \
    https://github.com/vatesfr/xen-orchestra.git upstream

# 3. Apply the community patch
cd upstream
git am ../patches/community-xoa-deploy.patch
cd ..

# 4. Install dependencies
cd upstream
corepack enable
yarn install
cd ..

# 5. Build XO Lite
cd upstream
yarn build:xo-lite
cd ..

# 6. Test the UI locally
# Set VITE_XO_HOST to a running XCP-ng host (full URL with protocol)
VITE_XO_HOST=wss://192.168.0.85 yarn --cwd upstream/packages/@xen-orchestra/lite dev
# Open http://localhost:5173 — navigate to /deploy-xoa to test the patched view
```

### Reaching the deploy view in the browser

XO Lite's `App.vue` hides all routes behind an auth gate (`v-if` on
`isConnected` store state). To reach `/deploy-xoa` without a live host for
UI testing, open the browser console on the XO Lite page and run:

```javascript
window.__vue_app__.config.globalProperties.$router.push('/deploy-xoa')
```

### Updating the patch for a new upstream version

```bash
# In a fresh upstream clone, make the changes manually
# then generate a new patch:
git diff HEAD > ../patches/community-xoa-deploy.patch
# or using format-patch for a clean commit:
git format-patch HEAD~1 -o ../patches/
```

---

## GPG signing

The RPM is signed with the community key during CI. Locally:

```bash
# Import the key
gpg --import RPM-GPG-KEY-xcp-ng-ce

# Sign the built RPM
rpm --addsign RPMS/x86_64/xo-lite-community-*.rpm
```

The public key (`RPM-GPG-KEY-xcp-ng-ce`) is sourced from the
[`xcp-ng/xcp-ng-release`](https://github.com/xcp-ng/xcp-ng-release) pattern
and committed to this repo.

---

## CI workflow (GitHub Actions)

The workflow triggers on push to `main` and on new tags matching `v*`.

Key steps:

```yaml
- name: Detect XO version
  run: echo "XO_VERSION=$(rpm -qp --qf '%{VERSION}' ...)" >> $GITHUB_ENV

- name: Clone upstream at tag
  run: git clone --depth 1 --branch v${{ env.XO_VERSION }} ...

- name: Apply patch
  run: git am patches/community-xoa-deploy.patch

- name: Build XO Lite
  run: |
    corepack enable
    yarn install
    yarn build:xo-lite

- name: Build RPM
  run: rpmbuild -ba SPECS/xo-lite-community.spec

- name: Sign RPM
  run: |
    echo "${{ secrets.GPG_PRIVATE_KEY }}" | gpg --import
    rpm --addsign RPMS/x86_64/xo-lite-community-*.rpm

- name: Publish release
  uses: softprops/action-gh-release@v1
  with:
    files: RPMS/x86_64/xo-lite-community-*.rpm
```

---

## Contributing

1. Fork [Vagrantin/xolite-ce](https://github.com/Vagrantin/xolite-ce).
2. To change the UI patch: edit `patches/community-xoa-deploy.patch`.
3. To change packaging: edit `SPECS/xo-lite-community.spec`.
4. Run the local development workflow above to verify changes.
5. Open a pull request against `main`.
