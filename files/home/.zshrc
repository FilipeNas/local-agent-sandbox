BREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"

# ── Options ──────────────────────────────────────────────────────────────────
setopt PROMPT_SUBST                 # required for $(kube_ps1) in the prompt
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

# ── History ──────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ── Completion ───────────────────────────────────────────────────────────────
# fpath must be set before compinit — it only scans once.
fpath=("$BREW_PREFIX/share/zsh/site-functions" "$HOME/.zsh/completions" $fpath)
autoload -Uz compinit && compinit -u

# ── Aliases ──────────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lahF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

alias k="kubectl"
alias kubectl=kubecolor
alias tg=terragrunt
alias tf=tofu
alias rr="rm -rf .terra*"

compdef kubecolor=kubectl           # kubecolor borrows kubectl's completion

# ── Prompt ───────────────────────────────────────────────────────────────────
PROMPT="%F{208}%n%f@%F{cyan}%m%f:%F{yellow}%c%f > "

# kube-ps1 must be sourced before kube_ps1 is referenced.
source "$BREW_PREFIX/opt/kube-ps1/share/kube-ps1.sh"
PROMPT='$(kube_ps1) '"$PROMPT"

# ── Tool integrations ────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"
source <(fzf --zsh)

# ── zsh plugins (last; syntax-highlighting after autosuggestions) ────────────
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

