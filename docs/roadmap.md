---
layout: default
title: Roadmap
nav_order: 3
---

# Roadmap
{: .no_toc }

Planned improvements and future direction for XCP-ng Community Edition.
{: .fs-6 .fw-300 }

{: .note }
This roadmap reflects current intent. Priorities can shift based on community
feedback and upstream changes. Open an issue on
[GitHub](https://github.com/Vagrantin/xcp-ce/issues) to propose or upvote items.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Near term — next release

These are actively being worked on or are well-defined enough to implement soon.

### Path B — GPG key injection into installer keyring
{: .d-inline-flex }

Security
{: .label .label-red }

Currently the community RPM repo is installed with `gpgcheck=false` passed as
a boot parameter (Path A). This is a pragmatic workaround. Path B will inject
the community GPG public key (`RPM-GPG-KEY-xcp-ng-ce`) directly into the
XCP-ng installer's RPM keyring during ISO assembly, enabling `gpgcheck=true`
with proper signature verification end-to-end.

**Tracked:** [xcp-ng-ce-iso GitHub Issues](https://github.com/Vagrantin/xcp-ng-ce-iso/issues)

---

### VIF auto-selection fix
{: .d-inline-flex }

Bug fix
{: .label .label-yellow }

During the XOA deployment flow, XO Lite's `filteredNetworks` list is sorted
alphabetically. This causes "Host internal management network" to be
auto-selected over the primary NIC-backed network — resulting in an XOA VM
with no usable external network interface.

**Fix:** filter networks that have no Physical Interface (PIF) association
before sorting, so only externally routable networks are offered for
auto-selection.

---

### Configurable xoa-proxy endpoint
{: .d-inline-flex }

Enhancement
{: .label .label-blue }

The `xoa-proxy` listen address and the XVA image path are currently
hardcoded (`http://192.168.0.1:3000/image.xva`). The next release will make
these configurable via a simple config file or environment variable, so
community members who host the image on a different server can adapt without
patching source code.

---

### Automated upstream version tracking
{: .d-inline-flex }

CI/CD
{: .label .label-green }

A GitHub Actions workflow will periodically check for new XCP-ng 8.x point
releases and XO Lite version bumps. When a new upstream tag is detected, it
will open a PR that updates the version pin and re-runs the full build
pipeline, giving maintainers a one-click release bump.

---

## Medium term

Items that are planned but require more design or upstream coordination.

### XCP-ng 8.4 / next major support
When XCP-ng 8.4 (or the next LTS) is released, CE will track it. The
two-repo build strategy (`xolite-ce` + `xcp-ng-ce-iso`) is designed to
make this straightforward — the patch file either applies cleanly or
surfaces as a build failure, prompting an intentional review.

### HTTPS-only XOA proxy with self-signed cert rotation
Replace the current HTTP/HTTPS dual-mode proxy with a hardened HTTPS-only
mode. The proxy will generate or rotate a self-signed certificate on first
boot, and XO Lite will be patched to trust it via a pinned fingerprint.

### Community XOA image update channel
Provide a documented, tested process for updating the bundled XOA image
to a newer Xen Orchestra release without reinstalling XCP-ng CE — using
the same `xoa-proxy` streaming mechanism but pointed at a new XVA.

### answerfile.xml automated install support
Provide an example `answerfile.xml` for fully unattended CE deployments
(PXE boot / scripted provisioning). This requires the answerfile to be
injected inside `install.img` (SquashFS), which the current build pipeline
already supports.

---

## Long term / ideas

These are possibilities the project is considering but has not committed to.

### Web-based community dashboard
A lightweight static page (no backend) served by `xoa-proxy` that shows
available XOA image versions, changelog, and a one-click update trigger.

### Multi-arch support
Explore building CE ISOs for ARM64 targets as XCP-ng upstream ARM support
matures.

### Community plugin registry
A mechanism for the community to distribute additional XO plugins via the
same RPM + GPG pipeline used for XO Lite CE.

---

## Completed

| Item | Released |
|---|---|
| Initial XO Lite patch (community deploy endpoint) | v8.3-ce Apr 2026 |
| `xoa-proxy` Rust streaming server | v8.3-ce Apr 2026 |
| Two-repo GPG-signed RPM + ISO build pipeline | v8.3-ce Apr 2026 |
| GitHub Actions free-tier CI/CD | v8.3-ce Apr 2026 |
| Read-only credential fields in XO Lite deploy view | v8.3-ce Apr 2026 |
