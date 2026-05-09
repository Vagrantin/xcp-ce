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
| Installer | XCP-ng text installer |

---

## Community customisations

### Patched XO Lite

XO Lite is the lightweight single-page management UI bundled with every
XCP-ng host. In Community Edition, the upstream `DeployXoaView.vue` component
is patched at **source level** before the RPM is built, so the patch is
minimal.

**What the patch changes:**

- The **"Deploy XOA"** button targets an update XOA deploy webpage.
- The user can now select the official Vates image.
- The image provided by Ronivay.
- A custom field to deploy you own XOA image.

Everything else in XO Lite — VM management, console access, SR browsing,
host metrics — remains untouched.

### xoa-proxy — local XVA delivery

A purpose-built **Rust HTTP server** (`xoa-proxy`) is bundled with the ISO
and runs on the host, It:

- Serves the community XOA image with support of gzip-compressed format.
- Supports both HTTP, HTTPS ( including self-signed certificate )

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


### Vates XOA image

This is the official Image provide by Vates for XCP-ng multi-host management.
In this case you can specify the credentials at deployment step.

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
  external connectivity required if you host your XOA image on your local network.

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

{: .warning }
**Some features require a license distributed by Vates**

---

## Known limitations in this release

| Limitation | Status |
|---|---|
| Xolite-ce - Deploy Button always accessible | issue#4(https://github.com/Vagrantin/xolite-ce/issues/4) - switch the button to access XOA |
| Xoa-proxy - Logs are in UTC | issue#3(https://github.com/Vagrantin/xoa-proxy/issues/3) - investigation to be done|
| Xoa-proxy - reduce the number of crates | issue#2(https://github.com/Vagrantin/xoa-proxy/issues/2) - investigation to be done |
| Xoa-proxy - Reduce memory footprint | issue#1(https://github.com/Vagrantin/xoa-proxy/issues/1) - xoa runs on Dom0 we must control it's impact on the performances |
| Xcp-ce - release publication versioning | issue#3() - versioning is currently all over the place and doesn't make any sense |
| Xcp-ce - GPG keys | issue#2() - GPG keys are not yet correctly manage and will have to be renewed a separated |

---

## Changelog
### v8.3-ce alpha2 (May 2026)
- Initial public release.
- First usable release.
- Provide basic feature to deploy from Vates, Ronivay or custom URL.

### v8.3-ce (April 2026)
- XO Lite patched: community deploy endpoint, read-only credential fields.
- `xoa-proxy` Rust server bundled: HTTP/HTTPS, gzip streaming.
- ISO assembled from upstream XCP-ng 8.3 with community RPM repo overlay.
- GPG key infrastructure (4096-bit RSA, `RPM-GPG-KEY-xcp-ng-ce`).
- GitHub Actions CI/CD pipeline: RPM build → ISO build → GitHub Releases.
