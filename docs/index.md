---
layout: home
title: Home
nav_order: 1
---

# XCP-ng Community Edition
{: .fs-9 }

A free, community-built XCP-ng ISO that replaces the official Xen Orchestra (Aka XOA)
with a fully **self-hosted** Xen Orchestra. The Goal is ease the deployment of 
community built XOA images essentially targeting home-labbers.
{: .fs-6 .fw-300 }

[Download latest ISO](https://github.com/Vagrantin/xcp-ng-ce-iso/releases/download/xcp-ng-ce-20260508-alpha2/xcp-ng-ce-8.3.iso){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/Vagrantin/xcp-ce){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## What is XCP-ng Community Edition?

[XCP-ng](https://xcp-ng.org/) is a powerful, open-source Type-1 hypervisor
based on the Xen Project. Officially it ships with **XO Lite**, a lightweight
in-browser management UI, and a one-click button that deploys the official
**Xen Orchestra Appliance (XOA)**.

**XCP-ng CE** keeps everything that makes XCP-ng great while replacing that
single button with a community-maintained workflow.
Once deployed you will be able to choose between 3 options to deploy XOA
Official Vates XOA image
Ronivay's pre-built image
You custom image


**Xen Orchestra** as of now you will have the choice between the image from Vates
or the image provided by Ronivay or deploy your own custom image.
One of the goal is to provide a strip down XOA image that remove the banner related
to the lack of support as well as remove all the features that requires a license
from Vates. This is to simplify the usage of XOA and remove menu features that are
not accessible out of the box.

---

## Download

{: .note }
All ISO and RPMs releases are signed with the **XCP-ng Community Edition GPG key**
(`RPM-GPG-KEY-xcp-ng-ce`). Verify your download before installing.

### Latest release — v8.3-ce (April 2026)

| File | Size | SHA256 |
|---|---|---|
| [`xcp-ng-8.3-ce.iso`](https://github.com/Vagrantin/xcp-ce/releases/latest) | ~650 MB | *(see release page)* |

[⬇ Download ISO](https://github.com/Vagrantin/xcp-ce/releases/latest){: .btn .btn-primary }
[Release notes](features){: .btn }

#### Verify the ISO

##### Get the community GPG key
[GPG Key](https://github.com/Vagrantin/xcp-ng-ce-iso/blob/main/RPM-GPG-KEY-xcp-ng-ce){: .btn }

```bash
# Verify the checksum file signature
gpg --verify RPM-GPG-KEY-xcp-ng-ce SHA256SUMS

# Verify the ISO
sha256sum -c SHA256SUMS
```

---

## Quick-start

### 1 · Install XCP-ng CE
Boot from the ISO. The installer is identical to upstream XCP-ng 8.3 —
follow the [official install guide](https://docs.xcp-ng.org/installation/install-xcp-ng/).

### 2 · Open XO Lite
After installation, point your browser at:

```
https://<your-host-ip>
```

Log in with your XCP-ng root credentials.

### 3 · Deploy XOA
In XO Lite, click **Deploy XOA**. The patched UI calls the bundled
[`xoa-proxy`](https://github.com/Vagrantin/xoa-proxy) which streams the
community XOA image (`image.xva`) directly to XAPI.

### 4 · Connect XO to your host
Once the XOA VM has started, open it in your browser and add your XCP-ng host:

```
Settings → Servers → Add server
Host : <your-XCP-host-ip>
User : root
```

---

## Architecture at a glance

```
┌──────────────────────────────────────────────────────────────┐
│                    XCP-ng CE Host                            │
│                                                              │
│  ┌──────────────┐   patch   ┌──────────────────────────────┐ │
│  │  XO Lite CE  │ ────────► │  DeployXoaView (community)   │ │
│  │              │           │                              │ │
│  └──────┬───────┘           └───────────┬──────────────────┘ │
│         │                               │ HTTP               │
│  ┌──────▼───────────────────────────────▼──────────────────┐ │
│  │                   xoa-proxy                             │ │
│  │       HTTP · HTTPS · gzip · streaming XVA delivery      │ │
│  └──────────────────────────┬──────────────────────────────┘ │
│                             │ XAPI VM.import                 │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │                   XAPI / Dom0                           │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## Components

| Repository | Role |
|---|---|
| [`xcp-ce`](https://github.com/Vagrantin/xcp-ce) | Documentation |
| [`xolite-ce`](https://github.com/Vagrantin/xolite-ce) | XO Lite community patch + RPM build |
| [`xcp-ng-ce-iso`](https://github.com/Vagrantin/xcp-ng-ce-iso) | ISO assembly pipeline and release |
| [`xoa-proxy`](https://github.com/Vagrantin/xoa-proxy) | Rust HTTP/gzip proxy for XVA delivery + RPM build |

Full technical details in the [Developer section](developers/).

---

## License

XCP-ng CE is released under the **GNU General Public License v3.0**.
It builds on upstream XCP-ng (Apache 2.0 / GPL components) and Xen Orchestra
(AGPL-3.0).

> XCP-ng Community Edition is an independent community project.
> It is not affiliated with, endorsed by, or supported by Vates SAS or the
> XCP-ng project.
