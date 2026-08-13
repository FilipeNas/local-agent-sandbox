# syntax=docker/dockerfile:1

# Prebuilt image for the Filipe local agent sandbox kit — tools baked in for fast
# starts. Homebrew and uv toolchains build as parallel stages; runtime ENV is
# last; --mount=type=cache persists the download caches across builds.

ARG BASE=docker/sandbox-templates:claude-code-docker-nightly

# ── system: shared base ───────────────────────────────────────────────────────
FROM ${BASE} AS system
USER root
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      build-essential procps curl file git iputils-ping \
 && rm -rf /var/lib/apt/lists/*


RUN cat > /etc/sandbox-persistent.sh <<'EOF'
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
EOF

# ── brew: Homebrew + CLI tools ────────────────────────────────────────────────
FROM system AS brew
USER agent
ARG TARGETARCH
ENV NONINTERACTIVE=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_ENV_HINTS=1
RUN --mount=type=cache,id=homebrew-$TARGETARCH,target=/home/agent/.cache/Homebrew,uid=1000,gid=1000 \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
RUN --mount=type=cache,id=homebrew-$TARGETARCH,target=/home/agent/.cache/Homebrew,uid=1000,gid=1000 \
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH" \
 && brew install \
      awscli awscurl awsdac docker-credential-helper-ecr fzf git-lfs helm ipcalc jq \
      krew kubecolor kubectx kubernetes-cli kustomize mysql-client nano nmap \
      opentofu pgcli ripgrep stern terraform-docs terragrunt \
      terraform-linters/tap/tflint websocat yq zoxide

# ── pytools: uv Python tools ──────────────────────────────────────────────────
FROM system AS pytools
USER agent
ARG TARGETARCH
RUN --mount=type=cache,id=uv-$TARGETARCH,target=/home/agent/.cache/uv,uid=1000,gid=1000 \
    for t in isort ruff pre-commit; do uv tool install "$t"; done

# ── final ─────────────────────────────────────────────────────────────────────
FROM system AS final
COPY --from=brew    --chown=agent:agent /home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew
COPY --from=pytools --chown=agent:agent /home/agent/.local         /home/agent/.local
USER agent
ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
ENV PATH="/home/agent/.krew/bin:\
${HOMEBREW_PREFIX}/opt/mysql-client/bin:\
${PATH}"
