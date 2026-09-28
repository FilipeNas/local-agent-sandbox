## Environment

You are running inside a Docker Sandbox microVM (Ubuntu 26.04), not on the
host, with Docker Engine installed — you can build and run containers directly.
The workspace is a bind mount of a real host directory: edits and deletions
here affect actual files on the developer's machine. Everything outside the
workspace is VM-local and disappears when the sandbox is removed.

The network policy is open — all outbound HTTP/HTTPS traffic is allowed.
Note that UDP and ICMP are blocked at the network layer, so `ping` and
DNS-over-UDP diagnostics will not work; use `curl` to test connectivity.

`sudo` is available without a password. The APT package cache is pre-populated
in `/var/lib/apt/lists`, so `sudo apt-get install <pkg>` works immediately without
needing `apt-get update`. Prefer `brew` for user-space tools.

## Tooling & Path Execution

All tools are pre-baked into the image (zero installation delay at startup).
The shell environment is configured via `BASH_ENV=/etc/sandbox-persistent.sh`,
guaranteeing PATH availability in both interactive sessions and automated
subshell tool calls:
- Homebrew: `/home/linuxbrew/.linuxbrew` (bin and sbin on PATH)
- Kubernetes: kubectl (aliased to kubecolor interactively), kubectx, krew (~/.krew/bin),
  kustomize, helm, stern
- IaC: opentofu (`tofu`), terragrunt, terraform-docs, tflint
- AWS: awscli, awscurl, awsdac, docker-credential-helper-ecr
- Data: pgcli, mysql client (keg-only on PATH)
- Shell: ripgrep, jq, yq, fzf, zoxide, nmap, ipcalc, websocat
- Python: ruff, isort, pre-commit (managed via `uv tool` — install more with
  `uv tool install <pkg>`)
- Agent: Antigravity CLI (`agy`) pre-installed at `/usr/local/bin/agy`

## Authentication & Security

Google OAuth authentication is handled by Docker Sandboxes' host credential proxy.
The local credential file (`~/.gemini/antigravity-cli/antigravity-oauth-token`)
contains proxy-managed sentinel strings; the host proxy swaps these for real
tokens when contacting Google API endpoints. The Docker Sandbox microVM serves
as the isolation boundary, allowing Antigravity to operate in YOLO mode
(`--dangerously-skip-permissions --mode=accept-edits`).
