# Docker Expert

Use this skill whenever the user asks anything about Docker — writing or debugging Dockerfiles,
building and tagging images, running containers, Docker Compose, volumes, networking, registries,
multi-stage builds, layer caching, security hardening, health checks, resource limits, Docker
Desktop, Docker Engine, container troubleshooting, image optimization, or publishing to Docker Hub
or any private registry. Also trigger for related terms like "container", "docker-compose.yml",
"docker run", "COPY", "RUN", "FROM", "docker build", "image size", "layer", "bind mount",
"named volume", "bridge network", "dockerfile best practices", or "container won't start".

---

## 1. Core Reference URLs

| Topic | URL |
|---|---|
| Docker docs home | https://docs.docker.com/ |
| Get started guide | https://docs.docker.com/get-started/ |
| Dockerfile reference | https://docs.docker.com/reference/dockerfile/ |
| docker CLI reference | https://docs.docker.com/reference/cli/docker/ |
| Docker Compose reference | https://docs.docker.com/reference/compose-file/ |
| Compose CLI reference | https://docs.docker.com/reference/cli/docker/compose/ |
| Build best practices | https://docs.docker.com/build/building/best-practices/ |
| Multi-stage builds | https://docs.docker.com/build/building/multi-stage/ |
| Networking overview | https://docs.docker.com/network/ |
| Storage / volumes | https://docs.docker.com/storage/ |
| Security overview | https://docs.docker.com/engine/security/ |
| Docker Hub | https://hub.docker.com/ |
| Docker Engine install | https://docs.docker.com/engine/install/ |
| Docker Desktop | https://docs.docker.com/desktop/ |
| Resource constraints | https://docs.docker.com/config/containers/resource_constraints/ |

---

## 2. Core Concepts

### The Container Model

```
┌──────────────────────────────────────────────────┐
│                   Host OS / Kernel               │
│                                                  │
│  ┌──────────────┐   ┌──────────────────────────┐ │
│  │  Docker      │   │       Containers          │ │
│  │  Engine      │◄──│  ┌──────┐  ┌──────┐      │ │
│  │  (daemon)    │   │  │ ctr1 │  │ ctr2 │ ...  │ │
│  └──────┬───────┘   │  └──────┘  └──────┘      │ │
│         │           └──────────────────────────-┘ │
│  ┌──────▼───────┐                                 │
│  │  Images      │  ← Dockerfile → docker build    │
│  │  (layers)    │                                 │
│  └──────────────┘                                 │
└──────────────────────────────────────────────────┘
```

### Key concepts table

| Concept | Description |
|---|---|
| **Image** | Read-only, layered snapshot. The blueprint for containers. |
| **Container** | A running (or stopped) instance of an image. Ephemeral by default. |
| **Layer** | One instruction in a Dockerfile = one immutable layer. Layers are cached and shared. |
| **Dockerfile** | Text file with instructions to build an image (`FROM`, `RUN`, `COPY`, `CMD`, etc.) |
| **Registry** | A store for images (Docker Hub, GHCR, ECR, private registry). |
| **Volume** | Persistent storage managed by Docker, survives container removal. |
| **Bind mount** | Maps a host path directly into a container. |
| **Network** | Virtual network connecting containers. Default driver: `bridge`. |
| **Docker Compose** | Tool to define and run multi-container apps via a `compose.yaml` file. |
| **BuildKit** | Modern build engine (default since Docker 23+). Faster, parallel, better caching. |

---

## 3. Dockerfile Reference

### Instruction quick reference

| Instruction | Purpose |
|---|---|
| `FROM image[:tag]` | Base image. Always the first instruction (except `ARG`). |
| `RUN command` | Execute command during build. Creates a new layer. |
| `COPY src dest` | Copy files from build context into image. Preferred over `ADD`. |
| `ADD src dest` | Like `COPY` but also handles URLs and auto-extracts tar archives. |
| `WORKDIR /path` | Set working directory for subsequent instructions. |
| `ENV KEY=value` | Set environment variable (persists into containers). |
| `ARG NAME=default` | Build-time variable (does NOT persist into containers). |
| `EXPOSE port` | Document which port the container listens on (informational). |
| `VOLUME ["/data"]` | Declare a mount point (creates anonymous volume if not mapped). |
| `USER user[:group]` | Switch to non-root user for subsequent instructions. |
| `CMD ["exec","arg"]` | Default command when container starts. Overridable at `docker run`. |
| `ENTRYPOINT ["exec"]` | Fixed command; `CMD` becomes its default args. |
| `HEALTHCHECK` | Define how Docker tests if the container is healthy. |
| `LABEL key=value` | Metadata (maintainer, version, description, etc.) |
| `ONBUILD instruction` | Trigger instruction when this image is used as a base. |
| `SHELL ["shell","flag"]` | Override default shell for `RUN`, `CMD`, `ENTRYPOINT`. |
| `STOPSIGNAL signal` | Signal sent to stop the container (default: `SIGTERM`). |

### Well-structured Dockerfile example

```dockerfile
# syntax=docker/dockerfile:1
# ── Build stage ─────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifests FIRST — maximises layer cache reuse
COPY package.json package-lock.json ./
RUN npm ci --include=dev

# Copy source and build
COPY . .
RUN npm run build

# ── Production stage ─────────────────────────────────────────
FROM node:20-alpine AS production

# Add metadata
LABEL org.opencontainers.image.title="My App" \
      org.opencontainers.image.version="1.0.0"

WORKDIR /app

# Install only production deps in clean layer
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy built output from builder stage
COPY --from=builder /app/dist ./dist

# Never run as root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

---

## 4. Multi-Stage Builds

Multi-stage builds let you **build fat, ship thin** — compile/test in a full-featured stage,
then copy only the artifacts into a minimal production image.

### Why it matters
- **Build stage** needs: compilers, SDKs, dev dependencies, test tools — all heavy.
- **Runtime stage** needs: only the compiled output + production runtime.
- Without multi-stage: build tools and source code ship to production → bloated images, larger attack surface.

### Named stage pattern

```dockerfile
# Stage 0 — named 'builder'
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server .

# Stage 1 — minimal final image
FROM scratch AS production
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Build only a specific stage
```bash
docker build --target builder -t myapp:debug .
```

### Copy from an external image
```dockerfile
COPY --from=nginx:latest /etc/nginx/nginx.conf /nginx.conf
```

### Common base image choices by runtime

| Runtime | Build Image | Production Image |
|---|---|---|
| Node.js | `node:20` | `node:20-alpine` or `node:20-slim` |
| Python | `python:3.12` | `python:3.12-slim` or `python:3.12-alpine` |
| Go | `golang:1.22` | `scratch` or `gcr.io/distroless/static` |
| Java | `eclipse-temurin:21-jdk` | `eclipse-temurin:21-jre-alpine` |
| Rust | `rust:1.78` | `debian:bookworm-slim` or `scratch` |

---

## 5. Layer Caching — Critical for Fast Builds

Docker invalidates the cache for a layer **and all layers after it** when the instruction
or its inputs change. Ordering matters enormously.

### The golden rule: most stable → least stable
```dockerfile
# SLOW (wrong order) — any code change re-runs npm install
COPY . .
RUN npm install

# FAST (correct order) — npm install only re-runs when package.json changes
COPY package.json package-lock.json ./
RUN npm install
COPY . .
```

### Cache-busting tips
- Combine `apt-get update` + `apt-get install` in ONE `RUN` to avoid stale cache:
  ```dockerfile
  RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      git \
   && rm -rf /var/lib/apt/lists/*
  ```
- Use `.dockerignore` to prevent irrelevant files from invalidating the `COPY . .` layer.

### `.dockerignore` (always include this)
```
.git
.gitignore
node_modules
**/__pycache__
**/*.pyc
*.log
.env
.DS_Store
README.md
tests/
docs/
```

---

## 6. Essential CLI Commands

### Images
```bash
docker build -t myapp:1.0 .                   # Build from Dockerfile in current dir
docker build -t myapp:1.0 -f path/Dockerfile  # Specify Dockerfile location
docker build --no-cache -t myapp:1.0 .        # Ignore cache
docker build --target builder -t myapp:dev .  # Build specific stage
docker images                                  # List local images
docker image inspect myapp:1.0                # Show image metadata and layers
docker history myapp:1.0                      # Show layer history and sizes
docker rmi myapp:1.0                          # Remove image
docker pull nginx:alpine                       # Pull from registry
docker push myrepo/myapp:1.0                  # Push to registry
docker tag myapp:1.0 myrepo/myapp:1.0         # Tag an image
```

### Containers
```bash
docker run nginx                               # Run container (foreground)
docker run -d nginx                            # Run detached (background)
docker run -d -p 8080:80 nginx                 # Map host:container port
docker run -d -v myvolume:/data nginx          # Mount named volume
docker run -d -v $(pwd):/app nginx             # Bind mount current dir
docker run --rm nginx                          # Remove container on exit
docker run -e MY_VAR=value nginx               # Set env var
docker run --name mycontainer nginx            # Named container
docker run --memory=512m --cpus=1.5 nginx      # Resource limits
docker run -it ubuntu bash                     # Interactive terminal
docker ps                                      # List running containers
docker ps -a                                   # Include stopped containers
docker stop mycontainer                        # Graceful stop (SIGTERM)
docker kill mycontainer                        # Force stop (SIGKILL)
docker rm mycontainer                          # Remove stopped container
docker exec -it mycontainer bash               # Shell into running container
docker logs mycontainer                        # View logs
docker logs -f mycontainer                     # Follow logs
docker inspect mycontainer                     # Full container metadata
docker stats                                   # Live resource usage
docker cp mycontainer:/app/file.log ./         # Copy file from container
```

### System
```bash
docker system df                               # Disk usage overview
docker system prune                            # Remove unused resources
docker system prune -a                         # Also remove unused images
docker volume prune                            # Remove unused volumes
docker image prune -a                          # Remove all unused images
```

---

## 7. Docker Compose

### `compose.yaml` anatomy

```yaml
name: myapp                          # Project name

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: production             # Build specific stage
    image: myapp:latest
    ports:
      - "8080:3000"                  # host:container
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://db:5432/mydb
    env_file:
      - .env                         # Load from file
    volumes:
      - uploads:/app/uploads         # Named volume
      - ./config:/app/config:ro      # Bind mount (read-only)
    depends_on:
      db:
        condition: service_healthy   # Wait for health check
    networks:
      - backend
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    networks:
      - backend

volumes:
  pgdata:
  uploads:

networks:
  backend:
    driver: bridge
```

### Essential Compose commands
```bash
docker compose up                     # Start all services (foreground)
docker compose up -d                  # Start detached
docker compose up --build             # Rebuild images first
docker compose down                   # Stop and remove containers
docker compose down -v                # Also remove volumes
docker compose ps                     # List service containers
docker compose logs -f web            # Follow logs for 'web' service
docker compose exec web bash          # Shell into service container
docker compose run --rm web npm test  # One-off command
docker compose pull                   # Pull latest images
docker compose restart web            # Restart specific service
docker compose scale web=3            # Scale service replicas
```

---

## 8. Networking

### Network drivers

| Driver | Description | Use Case |
|---|---|---|
| `bridge` | Default. Isolated virtual network on single host. | Most containers |
| `host` | Container shares host network namespace. | Performance-critical, Linux only |
| `none` | No networking. | Isolated/security workloads |
| `overlay` | Multi-host networking (Swarm). | Docker Swarm clusters |
| `macvlan` | Container gets its own MAC/IP on host network. | Legacy apps needing host-level access |

### Common networking patterns
```bash
# Create a custom network
docker network create mynet

# Run containers on the same network (they resolve by name)
docker run -d --name db --network mynet postgres:16
docker run -d --name app --network mynet -p 8080:3000 myapp

# From inside 'app', connect to 'db' by hostname: db:5432
```

### Container-to-host communication
- **Linux:** use `172.17.0.1` (default bridge gateway) or `host.docker.internal` (Docker 20.10+)
- **Mac/Windows:** use `host.docker.internal` (built-in)

---

## 9. Storage

### Three storage types

| Type | Command example | Persists? | Managed by | Use For |
|---|---|---|---|---|
| **Named volume** | `-v pgdata:/var/lib/postgresql/data` | ✅ Yes | Docker | Databases, persistent app data |
| **Bind mount** | `-v $(pwd)/src:/app/src` | ✅ Yes | Host OS | Development: live code reload |
| **tmpfs** | `--tmpfs /tmp` | ❌ No | Memory | Secrets, scratch space |

```bash
docker volume create pgdata             # Create named volume
docker volume ls                        # List volumes
docker volume inspect pgdata            # Show mount path, metadata
docker volume rm pgdata                 # Remove volume
```

---

## 10. Security Best Practices

```dockerfile
# 1. Pin base image versions (never use :latest in production)
FROM node:20.14.0-alpine3.20            # Exact version

# 2. Run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 3. Minimal base images reduce attack surface
FROM gcr.io/distroless/nodejs20-debian12  # No shell, no package manager

# 4. Never bake secrets into images
# WRONG:
ENV DB_PASSWORD=mysecretpassword

# RIGHT: inject at runtime
# docker run -e DB_PASSWORD=$DB_PASSWORD myapp
# or use Docker secrets / --secret flag with BuildKit

# 5. Use --secret for build-time secrets (BuildKit)
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm install

# 6. Read-only filesystem
docker run --read-only --tmpfs /tmp myapp

# 7. Drop Linux capabilities
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE myapp

# 8. Scan images for vulnerabilities
docker scout cves myapp:latest          # Docker Scout (built into Docker Desktop)
trivy image myapp:latest                # Trivy (open source, recommended)
```

---

## 11. Health Checks

```dockerfile
# HTTP service
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# TCP port check (if curl not available)
HEALTHCHECK CMD nc -z localhost 3000 || exit 1

# Custom script
HEALTHCHECK CMD ["/app/healthcheck.sh"]
```

```bash
# View health status
docker inspect --format='{{.State.Health.Status}}' mycontainer
# Values: starting | healthy | unhealthy
```

In Compose, use `condition: service_healthy` in `depends_on:` to enforce startup ordering.

---

## 12. Image Size Optimization Checklist

- [ ] Use multi-stage builds — build and runtime stages separated
- [ ] Use minimal base image (`alpine`, `slim`, `distroless`, `scratch`)
- [ ] Copy dependency manifests before source code (cache)
- [ ] Combine `RUN` instructions that relate to the same concern
- [ ] Remove package manager caches in same `RUN` layer: `&& rm -rf /var/lib/apt/lists/*`
- [ ] Add `.dockerignore` to exclude `node_modules`, `.git`, tests, docs
- [ ] Don't install debug tools in production stages
- [ ] Use `npm ci` (not `npm install`) for reproducible builds
- [ ] Use `--no-install-recommends` with `apt-get`
- [ ] Use `USER` to drop root privileges

---

## 13. Common Patterns (Ready-to-Use)

### Node.js (production-ready)
```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Python (FastAPI/Flask)
```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.12-slim AS production
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN useradd -m appuser && chown -R appuser /app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go (minimal scratch image)
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server .

FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

---

## 14. Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---|---|---|
| Container exits immediately | Process exits or crashes | `docker logs <c>` to see output; ensure `CMD` starts a foreground process |
| Port not accessible on host | Missing `-p` flag or wrong port | `docker ps` to verify port mapping; check `EXPOSE` in Dockerfile |
| `Permission denied` in container | Running as root on host-owned bind mount | Match UIDs or use named volumes instead |
| Image build very slow | Poor layer order / no cache | Move `COPY . .` after dependency install steps |
| `no such file or directory` | Wrong `WORKDIR` or path | Print `WORKDIR` with `RUN pwd`; check `COPY` source paths |
| Secret visible in `docker history` | Used `ENV` or `ARG` for secrets | Use BuildKit `--secret` or runtime env injection |
| Container can't reach DB by name | Not on same network | Use `--network` flag or define shared network in Compose |
| `HEALTHCHECK` always `unhealthy` | Wrong endpoint / missing tool | Exec into container and run the check command manually |
| Compose `depends_on` not waiting | Missing `condition: service_healthy` | Add `healthcheck:` to dependency service + `condition: service_healthy` |
| Disk space full | Accumulated dangling images/volumes | `docker system prune -a --volumes` |

### Debug an image layer by layer
```bash
# Build up to a specific stage and explore it
docker build --target builder -t debug-image .
docker run --rm -it debug-image sh

# Inspect layers and sizes
docker history myapp:latest --no-trunc
```

---

## 15. Glossary

| Term | Meaning |
|---|---|
| **Image** | Immutable, layered filesystem snapshot |
| **Container** | Running instance of an image |
| **Layer** | One immutable filesystem diff, produced by one Dockerfile instruction |
| **BuildKit** | Modern Docker build engine; parallel stages, `--secret`, better caching |
| **Multi-stage build** | Dockerfile with multiple `FROM` statements; separate build from runtime |
| **Named volume** | Docker-managed persistent storage |
| **Bind mount** | Host directory or file mounted into a container |
| **Bridge network** | Default isolated virtual network for containers on one host |
| **`.dockerignore`** | File listing paths to exclude from the build context |
| **`CMD`** | Default command for a container; overridable at `docker run` |
| **`ENTRYPOINT`** | Fixed executable; makes container behave like a command |
| **`ARG`** | Build-time variable (not available in running container) |
| **`ENV`** | Environment variable baked into the image and available in containers |
| **`HEALTHCHECK`** | Instruction defining how Docker monitors container health |
| **`scratch`** | Special empty base image for minimal static binaries |
| **`distroless`** | Google-maintained minimal images with no shell or package manager |
| **Docker Scout** | Docker's built-in vulnerability scanning tool |
| **Trivy** | Popular open-source container vulnerability scanner |
| **OCI** | Open Container Initiative — the standard image and runtime spec |
| **`docker compose`** | Compose V2 CLI plugin (replaces legacy `docker-compose`) |
