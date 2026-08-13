# local-agent-sandbox

My ready-to-run [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) kit for
coding agents. It boots an isolated microVM running Claude Code with a full
DevOps toolbelt — kubectl, opentofu, terragrunt, AWS CLI, pgcli, and more —
already baked into the image, so a sandbox starts in seconds instead of
installing tools at boot.

## Layout

- `Dockerfile` — the image: apt packages + Homebrew CLIs + uv Python tools.
- `spec.yaml` — the kit: image, network/env policy, entrypoint (Claude Code).
- `files/home/` — dotfiles shipped with the kit: bash config + Claude Code settings.
- `.github/workflows/` — CI (see below).

## How it works

- Tools are baked in at build time; a sandbox just pulls the image → fast start.
- `:latest` is rebuilt on every push to `main` and nightly.
- A release tags the image **and** kit by day — `2026-08-04.1`, `.2`, … — and
  also moves `:latest`.
- The kit is published to GHCR as an OCI artifact, so it can be run by reference.

Names:

- Image: `ghcr.io/filipenas/local-agent-sandbox`
- Kit: `ghcr.io/filipenas/local-agent-sandbox-kit`

## Install sbx

macOS 14+ on Apple silicon — see the [Docker docs](https://docs.docker.com/ai/sandboxes/get-started/).

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

# SSH access to sandboxes — needed for VS Code / Cursor Remote-SSH and Claude
# desktop. Writes ~/.ssh/config so `ssh <name>.sbx` connects (idempotent).
sbx setup ssh
```

After `sbx setup ssh`, connect to a running sandbox two ways:

- **Terminal:** `ssh filipe-sbx.sbx`
- **VS Code / Cursor:** install the **Remote - SSH** extension and connect to host
  `filipe-sbx.sbx` (Claude desktop works the same way).

## Run

Published kit (normal use):

```bash
# Claude Code — agent name must equal the kit name.
# First path is the writable workspace; add more, ':ro' = read-only.
sbx run --kit ghcr.io/filipenas/local-agent-sandbox-kit:latest \
  --name filipe-sbx filipe-local-agent-sandbox \
  ~/code/app ~/code/docs:ro

# A shell in the same sandbox instead
sbx exec -it filipe-sbx bash -l

# Manage
sbx ls
sbx stop filipe-sbx
sbx rm filipe-sbx
```

By default the workspace is bind-mounted, so the agent edits your real files.
With `--clone` the host dir (must be a repo) is copied and the agent works on a clone, 
so you can develop without affecting your real files

```bash
sbx run --clone --kit ghcr.io/filipenas/local-agent-sandbox-kit:latest \
  --name filipe-sbx filipe-local-agent-sandbox ~/code/app
```


From a local checkout (developing the kit):

```bash
sbx run --kit . --name filipe-sbx filipe-local-agent-sandbox .
```

## CI

- **build-and-push** — push to `main`, nightly, or manual → rebuilds `:latest` (image + kit).
- **release** — manual, from `main` → builds `:<date>.<n>` + `:latest` (image + kit) and creates the GitHub Release.
- **\_build** — the shared build both call (single source of truth).

## Build locally

```bash
docker buildx build -t ghcr.io/filipenas/local-agent-sandbox:latest --push .
sbx kit push . ghcr.io/filipenas/local-agent-sandbox-kit:latest
```

## Debug

Tail the sandbox daemon log:

```bash
SBX=~/Library/Application\ Support/com.docker.sandboxes/sandboxes/sandboxd
grep -iE 'error|panic|failed|kit' "$SBX/daemon.log" | tail -40
```

## Notes

- First push makes the GHCR package **private** — make it public so sandboxes can pull it.
