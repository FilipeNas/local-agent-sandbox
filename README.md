# local-agent-sandbox

My ready-to-run [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) kit for
coding agents. It boots an isolated microVM running Google's **Antigravity CLI (`agy`)**
with a full DevOps toolbelt — `kubectl`, `opentofu`, `terragrunt`, AWS CLI, `pgcli`,
`ripgrep`, `uv`, and more — already baked into the image, so a sandbox starts in seconds
instead of installing tools at boot.

## Layout

- `local-agent-sandbox.yaml` — the kit descriptor (v3 workload): declares capabilities (network policy, Google OAuth proxy, agent instructions, and lifecycle hook to seed permissive Antigravity settings).
- `context.md` — agent instructions authored for the kit, staged and loaded by Docker Sandboxes into the sandbox as `AGENTS.md`.
- `local-agent-sandbox.dockerfile` — the workload image recipe: Ubuntu 26.04 (`shell-docker`) + apt packages + Homebrew CLIs + uv Python tools + Antigravity CLI (`agy`) + dotfiles + entrypoint.
- `run.sh` — convenience script to launch the sandbox via `sbx run`.
- `files/home/` — dotfiles baked into the image: interactive bash config.
- `.github/workflows/` — CI (builds multi-arch v3 kit image).

## How it works

- **Bake-first approach**: Tools, configurations, and `agy` are baked in at build time; a sandbox starts in seconds.
- **Kit v3 OCI Image**: In Docker Sandboxes v3 (`sbx` >= 0.45), the kit *is* the container image itself. The YAML descriptor is validated by BuildKit (`# syntax=docker/sandbox-kit:3`) and embedded as an OCI manifest annotation.
- **Authentication**: Managed by Docker Sandboxes' host credential proxy. On the first run, `agy` switches to remote headless OAuth (`SSH_CONNECTION` forced) and prints a Google login URL. Sign in via your browser and paste back the callback URL. The host credential proxy securely manages tokens so subsequent sandboxes boot already authenticated.
- `:latest` is rebuilt on every push to `main` and nightly.
- A release tags the image by day — `2026-08-04.1`, `.2`, … — and also moves `:latest`.

Names:

- Image / Kit: `ghcr.io/filipenas/local-agent-sandbox` (also tagged `local-agent-sandbox-kit` for backwards compatibility)

## Install sbx

macOS 14+ on Apple silicon or Linux — see the [Docker docs](https://docs.docker.com/ai/sandboxes/get-started/).

```bash
brew trust docker/tap
brew install docker/tap/sbx
sbx login
```

## Setup (once)

```bash
# GitHub login with the scopes CI + GHCR need
gh auth login --git-protocol https --scopes "repo,workflow,read:packages,write:packages"

# Docker → GHCR (push/pull images and kits)
gh auth token | docker login ghcr.io -u FilipeNas --password-stdin

# sbx pull creds for GHCR (pull the private image + kit when creating a sandbox)
gh auth token | sbx secret set --registry ghcr.io --username FilipeNas --password-stdin

# Give sbx your GitHub token (global service secret)
sbx secret set -f -g github -t "$(gh auth token)"

# Allow kits only from these sources: base images (docker.io), kits pulled from
# your GitHub repos (git), and kits published to your GHCR namespace (OCI).
sbx settings set kit.allowedSources '["docker.io/","github.com/FilipeNas/","ghcr.io/filipenas/"]'

# SSH access to sandboxes — needed for VS Code / Cursor Remote-SSH.
# Writes ~/.ssh/config so `ssh <name>.sbx` connects (idempotent).
sbx setup ssh
```

After `sbx setup ssh`, connect to a running sandbox two ways:

- **Terminal:** `ssh filipe-sbx.sbx`
- **VS Code / Cursor:** install the **Remote - SSH** extension and connect to host
  `filipe-sbx.sbx`.

## Run

### First Run (OAuth Sign-In)

On the first start, Docker Sandboxes prompts you to approve the `antigravity` OAuth credential binding. `agy` then displays a Google sign-in URL:
1. Open the URL in your browser, sign in with your Google account, and grant access.
2. The browser redirects to `http://localhost:36742/oauth-callback?code=...` (which won't load in your browser; this is expected).
3. Copy the full redirect URL from the address bar and paste it into the sandbox terminal prompt.
4. Docker Sandboxes captures and stores the OAuth session on the host. Future sandboxes start already authenticated!

### Published kit (normal use)

```bash
# Antigravity CLI (agy)
# First path is the writable workspace; add more, ':ro' = read-only.
sbx run ghcr.io/filipenas/local-agent-sandbox-kit:latest \
  --name filipe-sbx \
  ~/code/app ~/code/docs:ro

# A shell in the same sandbox instead
sbx exec -it filipe-sbx bash -l

# Smoke test
sbx exec filipe-sbx -- sh -lc 'agy --help < /dev/null'

# Manage
sbx ls
sbx stop filipe-sbx
sbx rm filipe-sbx
```

By default the workspace is bind-mounted, so the agent edits your real files.
With `--clone` the host dir (must be a repo) is copied and the agent works on a clone:

```bash
sbx run --clone ghcr.io/filipenas/local-agent-sandbox-kit:latest \
  --name filipe-sbx ~/code/app
```

### From a local checkout (developing & testing the kit)

In v3, `sbx` directly builds and runs local kits from source using your local `local-agent-sandbox.dockerfile` and `local-agent-sandbox.yaml` descriptor without requiring a remote registry:

```bash
# Using the run.sh script:
./run.sh

# Or directly with sbx run:
sbx run . --name filipe-sbx .
```

## CI

- **build-and-push** — push to `main`, nightly, or manual → rebuilds `:latest` v3 kit image.
- **release** — manual, from `main` → builds `:<date>.<n>` + `:latest` and creates the GitHub Release.
- **\_build** — the shared build both call (single source of truth).

## Build locally

Build the v3 kit image using Docker Buildx (which validates the descriptor and embeds it into the OCI image):

```bash
# Build locally:
docker buildx build -f local-agent-sandbox.yaml -t ghcr.io/filipenas/local-agent-sandbox:latest .

# Or build and push to GHCR:
docker buildx build -f local-agent-sandbox.yaml -t ghcr.io/filipenas/local-agent-sandbox:latest --push .
```

## Debug

Tail the sandbox daemon log:

```bash
# macOS
SBX=~/Library/Application\ Support/com.docker.sandboxes/sandboxes/sandboxd
grep -iE 'error|panic|failed|kit' "$SBX/daemon.log" | tail -40

# Inspect sandbox network proxy log
sbx policy log filipe-sbx
```

## Notes

- First push makes the GHCR package **private** — make it public so sandboxes can pull it.
- To log out inside the sandbox, run `/logout` at the `agy` prompt.
