# Sourced on EVERY zsh invocation (interactive and not), so scripts and
# `zsh -c '...'` get brew, krew, and uv tools on PATH too.
if [ -f /etc/sandbox-persistent.sh ]; then
    . /etc/sandbox-persistent.sh
fi

# Child non-interactive bash shells (Claude Code's Bash tool, scripts).
export BASH_ENV=/etc/sandbox-persistent.sh

# 256-color support, needed for %F{208} in the prompt.
export TERM="${TERM:-xterm-256color}"

# ── Editor ───────────────────────────────────────────────────────────────────
export EDITOR="$HOMEBREW_PREFIX/bin/nano"
export VISUAL="$EDITOR"

# ── kubecolor ────────────────────────────────────────────────────────────────
export KUBECOLOR_PRESET="protanopia-dark"
export KUBECOLOR_OBJ_FRESH="10m"

# ── kube-ps1 ─────────────────────────────────────────────────────────────────
export KUBE_PS1_SYMBOL_ENABLE=false

