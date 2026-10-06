# agy-sandbox

A ready-to-run [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) kit for Google's **Antigravity CLI (`agy`)**.

It boots an isolated, hardware-virtualized microVM pre-configured with `agy` and a full DevOps toolbelt. Everything is pre-baked into the image so sandboxes start in seconds.

> [!NOTE]
> This project is heavily inspired by Oleg Šelajev's [agy-sbx-kit](https://github.com/shelajev/agy-sbx-kit).

---

## How It Works

- **Bake-First Architecture**: All tools, runtimes, and shell configurations are baked into the container image at build time for instant startup.
- **Docker Sandboxes Kit v3**: Uses the [Sandbox Kit v3 Spec](https://github.com/docker/sandbox-kit-spec) (`# syntax=docker/sandbox-kit:3`). The descriptor (`agy-sandbox.yaml`) configures network policies, OAuth proxying, agent instructions, and lifecycle hooks embedded directly into the OCI image.
- **Host-Managed OAuth Storage**:
  - Google OAuth tokens are **stored on your host machine** in the Docker Sandboxes credential store (`sbx`), **not** inside the ephemeral container session.
  - The sandbox only holds proxy sentinel placeholders (`agy-oauth-access-proxy-managed`). The host proxy intercepts outbound requests to Google AI APIs and injects the cached token.
- **Agent Context**: [`context.md`](context.md) is automatically injected as `AGENTS.md` inside the sandbox to guide agent behavior.

---

## Prerequisites & Setup

### 1. Install Docker Sandboxes CLI (`sbx`)
Follow the official Docker guide to install `sbx` on your system:  
**[Docker Sandboxes Installation Guide](https://docs.docker.com/ai/sandboxes/install/)**

### 2. Log In to Docker Sandboxes
Authenticate your CLI (required before creating or running sandboxes):
```bash
sbx login
```

### 3. Optional Settings
```bash
# Enable experimental platform features and UDP egress
sbx settings set platform.allowExperimentalFeatures true
sbx settings set feature.udp-egress true

# Allocate more disk space for the sandbox Docker volume (e.g. 20GB)
sbx settings set sandbox.disk.dockerVolume 20g

# Restart Docker sbx daemon to apply the new settings
sbx daemon restart

# Configure SSH access for terminal and VS Code / Cursor Remote-SSH (ssh <name>.sbx)
sbx setup ssh
```

---

## Quick Start (Run from GitHub Registry)

### 1. Authenticate with GitHub Container Registry (GHCR)
If pulling the pre-built kit from GHCR:
```bash
# Log in via GitHub CLI
gh auth login --scopes "read:packages"

# Allow sbx to pull kits from GHCR
gh auth token | docker login ghcr.io -u <your-github-username> --password-stdin
gh auth token | sbx secret set --registry ghcr.io --username <your-github-username> --password-stdin

# Allow kits from GHCR
sbx settings set kit.allowedSources '["docker.io/","ghcr.io/filipenas/"]'
```

### 2. Run a Sandbox
Mount a local project directory into the sandbox as a writable workspace:

```bash
sbx run ghcr.io/filipenas/agy-sandbox:latest --name filipe-sbx ~/Personal/my-project
```

### 3. First-Time Google OAuth Login
On your very first run (before credentials are saved on your host):
1. Antigravity (`agy`) will prompt with `/logout` due to missing credentials. Hit Enter (or type `/logout`) to open the login menu.
2. Select **`1. Google OAuth`**.
3. Open the provided Google URL in your host browser, sign in, and grant permissions.
4. Copy the authorization code shown in your browser, paste it into the terminal prompt, and press Enter.
5. Docker Sandboxes saves the token in your **host credential store** — all future sandboxes boot pre-authenticated!

---

## Workspace Modes & Git Workflows

When working with a Git repository, Docker Sandboxes supports two modes ([docs](https://docs.docker.com/ai/sandboxes/usage/#git-workspace-modes)):

- **Direct Mode (Default)**: The agent edits your host files directly. Changes appear immediately in your host working tree:
  ```bash
  sbx run ghcr.io/filipenas/agy-sandbox:latest --name filipe-sbx ~/Personal/my-project
  ```
- **Clone Mode (`--clone`)**: The agent works on an isolated in-container Git clone (triggered with `.` inside any local Git repository, or by passing a remote Git URL). Your host repo stays untouched:
  ```bash
  # Clone from a local git repository:
  sbx run --clone ghcr.io/filipenas/agy-sandbox:latest --name filipe-sbx .

  # Or clone directly from a remote Git URL:
  sbx run --clone ghcr.io/filipenas/agy-sandbox:latest --name filipe-sbx https://github.com/owner/repo.git
  ```

### Multiple Workspaces
The first directory is the primary workspace where the agent starts. Extra paths can be mounted read-only with `:ro` ([docs](https://docs.docker.com/ai/sandboxes/usage/#multiple-workspaces)):
```bash
sbx run ghcr.io/filipenas/agy-sandbox:latest ~/project-a ~/shared-libs ~/docs:ro
```

---

## Everyday Sandbox Management

```bash
# List running sandboxes
sbx ls

# Open an interactive Bash shell
sbx exec -it filipe-sbx bash -l

# Run a single command non-interactively
sbx exec filipe-sbx -- agy --help

# Stop and remove a sandbox
sbx stop filipe-sbx
sbx rm filipe-sbx
```

---

## Local Development (Building & Testing from Source)

### Fast Local Dev from Any Directory
To test changes to `agy-sandbox` quickly against another directory without publishing:

```bash
# From inside the directory you want the agent to work on:
sbx run ../agy-sandbox --name filipe-sbx .
```
`sbx` will automatically build the kit locally from source (`agy-sandbox.yaml` and `agy-sandbox.dockerfile`).

### Inspecting BuildKit Logs
When running a local kit, Docker Buildx builds the image in the background. If you need to inspect build output or diagnose errors:

```bash
# 1. List recent Buildx builds
docker buildx history ls

# 2. View full logs of a specific build ID
docker buildx history logs <build-id>
```

### Building the Kit Image with Docker Buildx
To build the OCI kit image manually:

```bash
# Build locally
docker buildx build -f agy-sandbox.yaml -t ghcr.io/filipenas/agy-sandbox:latest .

# Build and push directly to GHCR
docker buildx build -f agy-sandbox.yaml -t ghcr.io/filipenas/agy-sandbox:latest --push .
```

---

## References & Credits

- [Docker Sandbox Kit Specification](https://github.com/docker/sandbox-kit-spec)
- [Docker Sandboxes Official Documentation](https://docs.docker.com/ai/sandboxes/)
- [Docker Sandboxes Installation Guide](https://docs.docker.com/ai/sandboxes/install/)
- [Docker Sandboxes Git Workspace Modes](https://docs.docker.com/ai/sandboxes/usage/#git-workspace-modes)
- [Docker Sandboxes Multiple Workspaces](https://docs.docker.com/ai/sandboxes/usage/#multiple-workspaces)
- [Google Antigravity CLI Getting Started](https://antigravity.google/docs/getting-started)
- Inspired by [shelajev/agy-sbx-kit](https://github.com/shelajev/agy-sbx-kit)
