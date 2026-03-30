---
name: xcpng-xoa-expert
description: >
  Deep expert knowledge on the Xen hypervisor, XCP-ng (Xen Cloud Platform - next generation),
  and Xen Orchestra / XOA (Xen Orchestra Appliance). Use this skill whenever the user asks
  anything about: installing, configuring, upgrading, or troubleshooting XCP-ng hosts or pools;
  managing virtual machines, storage repositories, networking, or GPUs on XCP-ng; deploying,
  configuring, or operating Xen Orchestra (XOA or self-hosted XO); backup strategies and
  schedules in Xen Orchestra; XOSTOR (hyper-converged storage); XAPI internals; comparing
  XCP-ng to VMware/Proxmox; migration to XCP-ng; pool high-availability; delegating resources
  in XO; REST API or CLI usage; and any Xen Project (hypervisor, Dom0, DomU, PV/HVM) concepts.
  Trigger even if the user only mentions "XenServer", "XAPI", "Vates", "xo-cli", "xe CLI",
  "XOSTOR", "SR-IOV on XCP-ng", or "Vates Stack" — all of these imply this skill should be used.
---

# XCP-ng & Xen Orchestra Expert

## Core Reference URLs
Always fetch the most up-to-date information from these canonical sources before answering:

| Topic | URL |
|---|---|
| XCP-ng docs (main) | https://docs.xcp-ng.org/ |
| XCP-ng storage | https://docs.xcp-ng.org/storage/ |
| XCP-ng networking | https://docs.xcp-ng.org/networking/ |
| XCP-ng VMs | https://docs.xcp-ng.org/vms/ |
| XOSTOR | https://docs.xcp-ng.org/xostor/ |
| XCP-ng releases | https://docs.xcp-ng.org/releases/ |
| XO docs (main) | https://docs.xen-orchestra.com/ |
| XO backup | https://docs.xen-orchestra.com/backup |
| XO management | https://docs.xen-orchestra.com/manage |
| XO installation | https://docs.xen-orchestra.com/installation |
| Xen Project wiki | https://wiki.xenproject.org/wiki/Main_Page |
| Community forum | https://xcp-ng.org/forum |
| GitHub (Vates) | https://github.com/vatesfr/xen-orchestra |

---

## 1. The Vates Stack — Big Picture

```
┌─────────────────────────────────────────────────────────┐
│              Xen Orchestra (XOA / self-hosted)          │
│  Web UI  ·  REST API  ·  xo-cli  ·  Terraform provider │
│              Backup  ·  Monitoring  ·  Delegation        │
└────────────────────────┬────────────────────────────────┘
                         │  XAPI (Xen API)
┌────────────────────────▼────────────────────────────────┐
│                  XCP-ng Pool                            │
│  Pool Master  ◄──────────►  Pool Slaves (hosts)         │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │   Dom0   │  │  DomU    │  │  Storage (SR)        │  │
│  │ (Control)│  │  (VMs)   │  │  NFS·iSCSI·XOSTOR   │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
└────────────────────────────────────────────────────────-┘
                         │
          ┌──────────────▼──────────────┐
          │       Xen Hypervisor        │
          │  (Type-1, bare-metal, LF)   │
          └─────────────────────────────┘
```

**Key principle:** XCP-ng is a complete, turnkey bare-metal hypervisor ISO. All management
(stateful) goes through XAPI. XOA/XO is the recommended stateful management layer — it runs
in a dedicated VM (or as a self-hosted Node.js app) and connects to the pool master via XAPI.

---

## 2. The Xen Hypervisor Foundation

### Dom0 vs DomU
- **Dom0** (Domain 0): The privileged control domain. Runs a modified Linux kernel. Hosts the
  XAPI toolstack, device drivers, and the management interface. Always started first.
- **DomU** (Domain U): Unprivileged guest VMs. Can be:
  - **PV (Paravirtualized):** Guest OS is aware it's virtualized; uses Xen-specific interfaces.
    Higher performance on older hardware, requires OS modification.
  - **HVM (Hardware Virtual Machine):** Full hardware emulation via Intel VT-x/AMD-V. Standard
    OS images boot unmodified.
  - **PVH:** Modern hybrid — HVM container with PV drivers. Recommended for modern Linux.

### XAPI (Xen API)
- XML-RPC / JSON-RPC API exposed on each host.
- All XCP-ng clients (XO, `xe` CLI, OpenStack, Terraform) speak XAPI.
- Pool master is the single point of truth; connect clients to the master's IP only.

---

## 3. XCP-ng Deep Dive

### 3.1 Installation
- Download ISO from https://docs.xcp-ng.org/installation/install-xcp-ng/#download-and-create-media
- Supported installation targets: physical servers, some cloud environments, nested virt (for labs)
- Key installer options: disk layout, SR (Storage Repository) type, management NIC
- After install: configure via `xe` CLI or connect XOA/XO

### 3.2 Pool Concepts
- **Pool**: one or more XCP-ng hosts sharing configuration, storage, and network settings.
- **Pool Master**: the host that holds the authoritative XAPI database. Other hosts are slaves.
- Pool master election happens automatically on failure (if HA is configured).
- All VM migrations and cross-host operations go through the pool master.

### 3.3 Storage Repositories (SR)
| SR Type | Protocol | Use Case |
|---|---|---|
| Local LVM | Local disk | Single-host, no live migration |
| NFS | NFS v3/v4 | Shared, easy setup |
| iSCSI (LVM) | iSCSI | High performance shared |
| iSCSI (EXT) | iSCSI | File-level on iSCSI |
| HBA/Fibre Channel | FC | Enterprise SAN |
| XOSTOR | DRBD/LINSTOR | Hyper-converged, replicated |
| SMB/CIFS | SMB | Windows file shares |
| ISO SR | NFS/local | Store ISO images |

**XOSTOR** is XCP-ng's hyper-converged storage solution — DRBD-backed, managed via LINSTOR,
deeply integrated. Requires minimum 3 nodes. See https://docs.xcp-ng.org/xostor/

### 3.4 Networking
- XCP-ng uses **Open vSwitch (OVS)** by default for VM networking.
- Concepts: PIFs (physical interfaces), VIFs (virtual interfaces), Networks, Bonds, VLANs.
- SR-IOV: pass NIC virtual functions directly to VMs for near-native performance.
- Bonds: active-backup, LACP (802.3ad), balance-slb.
- VLAN tagging: create VLAN networks on top of a physical network.

### 3.5 Virtual Machines
- **Templates**: base configurations for quick VM creation.
- **Snapshots**: point-in-time copies (disk + optionally memory).
- **Live Migration (XenMotion)**: move running VMs between hosts in the pool without downtime.
- **Storage XenMotion**: migrate VMs across storage repositories while running.
- **GPU / vGPU**: passthrough (hardware) and vGPU (NVIDIA GRID) supported.
- **PCI passthrough**: for direct device access in VMs.

### 3.6 `xe` CLI
The low-level CLI tool running on Dom0 or from a remote machine:
```bash
# List VMs
xe vm-list

# Start a VM
xe vm-start uuid=<VM_UUID>

# Create a snapshot
xe vm-snapshot vm=<name> new-name-label=<snap-name>

# Migrate VM to another host
xe vm-migrate vm=<name> host=<destination-host>
```
Full reference: `xe help --all` on the host or the XCP-ng docs.

### 3.7 Releases and Upgrade Path
- XCP-ng follows a predictable release cycle (LTS + standard releases).
- Upgrades: in-place via ISO installer (preserve existing data) or using XO's rolling pool upgrade.
- Always check: https://docs.xcp-ng.org/releases/ for current supported versions.

---

## 4. Xen Orchestra (XO / XOA) Deep Dive

### 4.1 Two Deployment Modes
| Mode | Description |
|---|---|
| **XOA** (Xen Orchestra Appliance) | Pre-built VM image deployed on XCP-ng. Easiest. Commercial subscriptions. |
| **XO from source** | Self-compiled Node.js app. Free, community-supported. More work to maintain. |

Quick deploy (XOA): https://vates.tech/deploy/ — login and use the deploy form.
Self-hosted install: https://docs.xen-orchestra.com/installation

### 4.2 Core Features

#### Management
- **Web UI**: Full lifecycle management of hosts, pools, VMs, SRs, networks.
- **REST API**: Programmatic access to all XO resources.
- **xo-cli**: Command-line interface that connects to XO server:
  ```bash
  xo-cli --register wss://your-xo-host admin@admin.net password
  xo-cli vm.list
  xo-cli vm.start id=<vm-uuid>
  ```
- **Terraform provider**: Infrastructure-as-code for VM provisioning.
- **Packer / Ansible**: Integration for image building and configuration management.

#### Backup
XO provides agentless backup directly from the hypervisor layer:

| Backup Type | Description |
|---|---|
| **Full backup** | Complete VM export to remote storage |
| **Delta backup** | Only changed blocks since last backup (efficient) |
| **Continuous Replication (CR)** | Near-realtime replication to another XCP-ng pool |
| **Disaster Recovery (DR)** | Full copy to remote site with restore capability |
| **File-level restore** | Restore individual files from backup without full VM restore |
| **Schedule** | Cron-based schedules, retention policies |

Remote backup storage supported: NFS, SMB, S3-compatible, local disk.

#### Delegation & Multi-tenancy
- RBAC: roles (Admin, Operator, Viewer) per resource group.
- Resource sets: limit vCPU, RAM, disk quota per user/group.
- Self-service portal: delegated users manage their own VMs within quotas.

#### Monitoring
- Performance metrics: CPU, RAM, network, disk I/O per VM and host.
- Alerts: configurable thresholds with notifications (email, Slack, etc.)
- Health dashboard: overview of pool health, running/stopped VMs, SR usage.

### 4.3 High Availability (HA)
- XCP-ng pool HA: automatic VM restart on host failure (requires shared SR + heartbeat disk).
- Configure HA via XO: Infra → Pools → HA settings.
- HA uses a fencing mechanism (STONITH-style) to avoid split-brain.

### 4.4 Load Balancing
- XO's **XOSAN** (deprecated) replaced by XOSTOR.
- XO **Load Balancer** plugin: automatically migrates VMs to balance CPU/RAM load across hosts.

---

## 5. Common Workflows (Step-by-Step Patterns)

### Add a new XCP-ng host to XO
1. In XO web UI → Settings → Servers → Add Server
2. Enter host IP, credentials (root or API user), optional name
3. XO connects via XAPI — host and all its VMs/SRs appear immediately

### Create a VM
1. XO → New VM → select pool and template
2. Configure: vCPUs, RAM, disk size, network, ISO/template
3. Click Create → optionally Start immediately

### Schedule a Delta Backup
1. XO → Backup → New Backup Job
2. Mode: Delta Backup
3. Select VMs (by tag, pool, or individual)
4. Configure remote (NFS/SMB/S3), retention, schedule (cron)
5. Save — runs automatically per schedule

### Rolling Pool Upgrade
1. XO → Infra → Pool → Rolling Update
2. XO live-migrates VMs off each host, upgrades the host, reboots, continues
3. Zero-downtime upgrade for running VMs (requires shared SR)

### Setup XOSTOR (Hyper-converged)
1. Requires 3+ XCP-ng hosts, each with dedicated SSDs/HDDs for XOSTOR
2. In XO → XOSTOR → Create new XOSTOR
3. Select hosts, disks, replication factor (2 or 3)
4. XOSTOR SR appears and is usable immediately
5. Full guide: https://docs.xcp-ng.org/xostor/

---

## 6. Troubleshooting Quick Reference

| Symptom | First Steps |
|---|---|
| VM won't start | Check SR space, check host RAM, `xe vm-start` for detailed error |
| Can't connect pool to XO | Verify XAPI port 443/80 open, check credentials, check pool master IP |
| Live migration fails | Check shared SR available on both hosts, check network connectivity |
| SR shows degraded | Check underlying storage, `xe sr-scan uuid=<SR>`, check disk health |
| Dom0 high CPU | Check for runaway VMs, `top` in Dom0, review XAPI logs `/var/log/xensource.log` |
| XOA unreachable | Access XOA console directly, check Node.js service: `systemctl status xo-server` |
| XOSTOR degraded | Check DRBD status: `drbdadm status`, LINSTOR: `linstor node list` |

Key log locations on XCP-ng host:
- XAPI: `/var/log/xensource.log`
- Dom0 kernel: `dmesg` or `/var/log/kern.log`
- DRBD (XOSTOR): `/var/log/drbd.log`

---

## 7. Comparison: XCP-ng vs Alternatives

| Feature | XCP-ng + XO | VMware vSphere | Proxmox VE |
|---|---|---|---|
| License | Open source (+ paid XOA) | Commercial | Open source (+ paid support) |
| Hypervisor | Xen (Type-1) | ESXi (Type-1) | KVM (Type-1) |
| Management | Xen Orchestra | vCenter | Web UI / CLI |
| Backup (built-in) | Yes (XO, agentless) | Requires vSphere plugin | Yes (PBS) |
| Hyper-converged | XOSTOR | vSAN | Ceph |
| HA | Yes | Yes | Yes |
| Live Migration | XenMotion | vMotion | Yes |
| API | XAPI + REST | vSphere API | REST API |
| GPU Passthrough | Yes | Yes | Yes |

---

## 8. Key Terminology Glossary

| Term | Meaning |
|---|---|
| **XAPI** | Xen API — the management API for XCP-ng hosts |
| **Dom0** | Control domain; hosts the hypervisor toolstack |
| **DomU** | Guest VM (unprivileged domain) |
| **PV / HVM / PVH** | Paravirtualized / Hardware VM / PV in HVM container |
| **SR** | Storage Repository — a storage pool (local, NFS, iSCSI, etc.) |
| **PIF** | Physical Interface — a real NIC as seen by XAPI |
| **VIF** | Virtual Interface — a VM's virtual NIC |
| **VDI** | Virtual Disk Image — a disk within a SR |
| **VBD** | Virtual Block Device — connection between VM and VDI |
| **XOA** | Xen Orchestra Appliance — pre-built VM for managing XCP-ng |
| **XOSTOR** | XCP-ng's hyper-converged storage (DRBD + LINSTOR) |
| **XenMotion** | Live migration of running VMs between hosts |
| **Pool Master** | The authoritative host in a pool (holds XAPI DB) |
| **HA** | High Availability — auto-restart VMs on host failure |
| **CR** | Continuous Replication — near-realtime VM replication in XO |
| **DR** | Disaster Recovery backup mode in XO |

---

## 9. Answer Quality Standards

When responding to questions using this skill:

1. **Always fetch live docs** for version-specific questions (releases, feature availability, hardware support) using the URLs in Section 1.
2. **Be specific with commands** — provide exact `xe` or `xo-cli` commands with realistic placeholders.
3. **Distinguish XOA vs self-hosted XO** when installation or update procedures differ.
4. **Mention prerequisites** (e.g., shared SR required for XenMotion, min 3 hosts for XOSTOR).
5. **Link to canonical docs** so the user can dig deeper.
6. **For troubleshooting**: always provide log file paths and diagnostic commands alongside explanations.
7. **Community forum** (https://xcp-ng.org/forum) is a valuable resource — mention it for niche or version-specific issues.
