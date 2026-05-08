---
layout: default
title: Features
nav_order: 2
---

# Features — v8.3-ce
{: .no_toc }

Current release · April 2026 · Based on XCP-ng 8.3
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Base platform

XCP-ng CE is a **drop-in ISO replacement** for XCP-ng 8.3. It inherits the
full upstream feature set — the only differences are in XO Lite and the
deployment workflow. Everything below the installer works exactly as in
the official release.

| Attribute | Value |
|---|---|
| Base release | XCP-ng 8.3 (latest upstream point release) |
| Hypervisor | Xen 4.17 |
| Dom0 kernel | Linux 4.19 (XCP-ng kernel) |
| Management API | XAPI (Xen API) |
| Default networking | Open vSwitch (OVS) |
| Installer | XCP-ng text installer (unchanged) |

---

## Community customisations

### Patched XO Lite

XO Lite is the lightweight single-page management UI bundled with every
XCP-ng host. In Community Edition, the upstream `DeployXoaView.vue` component
is patched at **source level** before the RPM is built, so the patch is
minimal and rebasing against new upstream releases is straightforward.

**What the patch changes:**

- The **"Deploy XOA"** button targets the community `xoa-proxy` endpoint
  instead of `vates.tech`.
- The credential fields are **read-only** and pre-filled with the community
  XOA defaults (`admin@admin.net` / `admin` / SSH `xo` / `xopass`).
- All phone-home behaviour in the deploy flow is removed.

Everything else in XO Lite — VM management, console access, SR browsing,
host metrics — remains untouched.

### xoa-proxy — local XVA delivery

A purpose-built **Rust HTTP server** (`xoa-proxy`) is bundled with the ISO
and runs on the host during the deploy flow. It:

- Serves the community XOA image (`image.xva`) as a gzip-compressed byte
  stream using async I/O (`tokio` + `hyper`).
- Sets `Content-Encoding: gzip` so XAPI decompresses transparently on receipt
  — no temporary file needed, no memory exhaustion.
- Supports both HTTP and HTTPS.
- Keeps no logs and holds no persistent state.

Because the proxy streams directly from disk, even hosts with limited RAM
can import a multi-gigabyte XVA without issues.

### Community XOA image

The XOA image deployed by the proxy is built from
[ronivay/XenOrchestraInstallerUpdater](https://github.com/ronivay/XenOrchestraInstallerUpdater),
a well-maintained community installer for self-hosted Xen Orchestra.

| Detail | Value |
|---|---|
| XO version | Tracks latest stable XO release |
| Default admin user | `admin@admin.net` |
| Default admin password | `admin` |
| SSH user | `xo` |
| SSH password | `xopass` |

{: .warning }
**Change the default passwords immediately** after first login.

---

## What you get (full feature summary)

### Hypervisor & host management

- **Full XCP-ng 8.3 feature set** — all VM types (HVM, PV, PVH), live
  migration (XenMotion), Storage XenMotion.
- **Open vSwitch networking** — VLANs, bonds (active-backup, LACP,
  balance-slb), SR-IOV.
- **Storage Repositories** — Local LVM, NFS, iSCSI (LVM & EXT), HBA/FC,
  XOSTOR (hyper-converged), SMB, ISO SR.
- **GPU/vGPU** — PCI passthrough and NVIDIA GRID vGPU support.
- **HA** — pool high-availability with automatic VM restart on host failure.

### XO Lite (browser-based quick management)

Available at `https://<host-ip>` immediately after install:

- Pool and host overview (CPU, RAM, storage at a glance).
- VM list: start, stop, reboot, console access.
- Basic SR and network inspection.
- **Community deploy flow** (patched): one-click XOA deployment with no
  external connectivity required.

### Xen Orchestra (after XOA deployment)

After clicking "Deploy XOA" in XO Lite, you get a full Xen Orchestra instance:

- **Full lifecycle VM management** — create, clone, migrate, snapshot.
- **Agentless backup** — full, delta, continuous replication, disaster recovery.
- **Scheduling** — cron-based backup jobs with configurable retention.
- **RBAC / delegation** — roles (Admin, Operator, Viewer) and resource sets.
- **Monitoring & alerting** — per-VM and per-host metrics, threshold alerts.
- **REST API + xo-cli** — scriptable access to all resources.
- **Rolling pool upgrade** — zero-downtime upgrades via XO.
- **XOSTOR** — hyper-converged storage setup via the XO UI (3+ nodes).

---

## Known limitations in this release

| Limitation | Status |
|---|---|
| GPG verification uses `gpgcheck=false` at boot (Path A) | Path B (injecting community key into installer keyring) tracked in [GitHub Issues](https://github.com/Vagrantin/xcp-ng-ce-iso/issues) |
| VIF auto-selection may pick "Host internal management network" instead of the primary NIC | Known bug — fix planned for next release (see [Roadmap](roadmap)) |
| `xoa-proxy` endpoint URL is currently hardcoded at `http://192.168.0.1:3000` | Configurable endpoint planned |
| Tested on physical x86-64 hardware and nested virtualisation only | ARM / other arches not targeted |

---

## Changelog

### v8.3-ce (April 2026)
- Initial public release.
- XO Lite patched: community deploy endpoint, read-only credential fields.
- `xoa-proxy` Rust server bundled: HTTP/HTTPS, gzip streaming.
- ISO assembled from upstream XCP-ng 8.3 with community RPM repo overlay.
- GPG key infrastructure (4096-bit RSA, `RPM-GPG-KEY-xcp-ng-ce`).
- GitHub Actions CI/CD pipeline: RPM build → ISO build → GitHub Releases.
