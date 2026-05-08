---
layout: default
title: xoa-proxy
parent: Developers
nav_order: 1
---

# xoa-proxy
{: .no_toc }

Rust HTTP/HTTPS proxy that streams the community XOA image to XAPI.
{: .fs-6 .fw-300 }

**Repository:** [Vagrantin/xoa-proxy](https://github.com/Vagrantin/xoa-proxy)
· Language: Rust · License: GPL-3.0

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Purpose

When XO Lite's patched "Deploy XOA" button is clicked, XAPI needs to import
a `.xva` VM archive. XAPI calls `VM.import` with a URL — it expects the server
at that URL to serve the file over HTTP.

The challenge is that a standard XVA can be several gigabytes. Loading it into
memory before serving it would exhaust Dom0 RAM. `xoa-proxy` solves this by
**streaming** the file from disk directly to the XAPI caller using Rust's async
I/O, with no intermediate buffering.

Additionally, XVA files are not inherently compressed, making network transfer
slow on low-bandwidth management networks. `xoa-proxy` serves the file with
`Content-Encoding: gzip`, letting XAPI decompress on the fly while receiving —
the disk image itself can be stored pre-compressed or plain.

---

## Design

### Technology choices

| Choice | Rationale |
|---|---|
| **Rust** | Memory safety without GC pauses; ideal for a long-lived server process in Dom0 |
| **hyper** (async HTTP) | Low overhead, no framework bloat; direct control over response headers |
| **tokio** async runtime | First-class async I/O; `tokio::fs::File` integrates naturally with hyper |
| **tokio_util::io::ReaderStream** | Converts an async file reader into a `Stream<Item = Bytes>` that hyper can consume chunk by chunk — the key to zero-copy streaming |

### Request flow

```
XO Lite (browser)
    │  HTTP GET /image.xva
    ▼
xoa-proxy (Rust / hyper)
    │  Open image.xva from disk
    │  Build HTTP 200 response:
    │    Content-Type: application/octet-stream
    │    Content-Encoding: gzip
    │    Transfer-Encoding: chunked
    │  Stream via ReaderStream → hyper body
    ▼
XAPI VM.import
    │  Decompresses gzip on the fly
    │  Writes VDIs to local SR
    ▼
XOA VM created
```

### HTTP vs HTTPS

The proxy supports both. In the current release the XO Lite patch targets
the HTTP endpoint (`http://192.168.0.1:3000`). HTTPS support is present in
the codebase for future use when the certificate trust story is resolved
(see [Roadmap](../roadmap)).

---

## Code structure

```
xoa-proxy/
├── src/
│   └── main.rs        ← HTTP server, request handler, streaming logic
├── tests/             ← Integration tests
├── .cargo/            ← Cargo config (cross-compile settings)
├── Cargo.toml         ← Dependencies: hyper, tokio, tokio-util, ...
└── Cargo.lock
```

### Core streaming pattern

The heart of the proxy is converting a `tokio::fs::File` into a hyper response
body without loading the whole file into memory:

```rust
use tokio_util::io::ReaderStream;
use hyper::Body;

let file = tokio::fs::File::open("image.xva").await?;
let stream = ReaderStream::new(file);
let body = Body::wrap_stream(stream);

let response = Response::builder()
    .header("Content-Type", "application/octet-stream")
    .header("Content-Encoding", "gzip")
    .body(body)?;
```

Each chunk is read from disk and forwarded to the TCP socket immediately.
Dom0 RAM usage is bounded by the hyper chunk size, not the file size.

---

## Building

### Prerequisites

- Rust toolchain (stable) — install via [rustup](https://rustup.rs/)
- For cross-compilation to Dom0: `x86_64-unknown-linux-musl` target

```bash
# Native build (for testing)
cargo build --release

# Cross-compile for Dom0 (static musl binary)
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
```

The resulting binary at `target/x86_64-unknown-linux-musl/release/xoa-proxy`
is a fully static executable with no shared library dependencies — suitable
for embedding in the XCP-ng DOM0 environment.

### Running locally for development

```bash
# Place a test XVA (or any large file) at the expected path
cp /path/to/test.xva image.xva

# Start the proxy
./target/release/xoa-proxy

# Test streaming in another terminal
curl -v http://127.0.0.1:3000/image.xva -o /dev/null
```

---

## Configuration

In the current release the listen address and image path are hardcoded.
Making them configurable is on the [Roadmap](../roadmap).

| Parameter | Current value |
|---|---|
| Listen address | `0.0.0.0:3000` |
| Image path | `image.xva` (relative to working directory) |
| Image metadata | `image.txt` (served alongside the XVA) |

---

## Integration with XO Lite CE

The XO Lite patch in [`xolite-ce`](xolite-ce) sets the deploy URL to
`http://192.168.0.1:3000/image.xva`. This is the address `xoa-proxy` listens
on when started on a XCP-ng CE host where `192.168.0.1` is the management
interface IP.

{: .warning }
If your management network uses a different subnet, the hardcoded IP will not
match. A configurable endpoint is planned for the next release.

---

## Testing

```bash
# Run unit and integration tests
cargo test

# Tests are in tests/
# They spin up the proxy on a random port and verify streaming behaviour
```

---

## Contributing

1. Fork [Vagrantin/xoa-proxy](https://github.com/Vagrantin/xoa-proxy).
2. Create a branch: `git checkout -b feature/my-change`.
3. Run `cargo fmt` and `cargo clippy` before committing.
4. Open a pull request against `main`.
