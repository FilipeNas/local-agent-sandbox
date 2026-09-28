# Brew env for interactive shells (non-interactive bash gets it via BASH_ENV).
[ -f /etc/sandbox-persistent.sh ] && . /etc/sandbox-persistent.sh

# Env
export TERM="${TERM:-xterm-256color}"
export EDITOR="$HOMEBREW_PREFIX/bin/nano"
export VISUAL="$EDITOR"
export KUBECOLOR_PRESET="protanopia-dark"
export KUBECOLOR_OBJ_FRESH="10m"

# Interactive shells only below this line.
case $- in *i*) ;; *) return ;; esac

# History
HISTFILE=~/.bash_history
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups   # ignore dups and space-prefixed commands
shopt -s histappend                 # append across sessions, don't overwrite

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lahF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias k='kubectl'
alias kubectl='kubecolor'
alias rr='rm -rf .terra*'

# Completion
# Load kubectl's bash completion (defines __start_kubectl), then let kubecolor
# and k borrow it. `command` bypasses the kubectl→kubecolor alias above.
source <(command kubectl completion bash)
complete -o default -F __start_kubectl kubecolor k

# Prompt: host  cwd ❯  (arrow turns red after a failed command)
__prompt() {
  local ec=$?
  local arrow
  if [ "$ec" -eq 0 ]; then arrow='\[\e[38;5;212m\]❯\[\e[0m\]'; else arrow='\[\e[38;5;203m\]❯\[\e[0m\]'; fi
  PS1="\[\e[33m\]\h\[\e[0m\] \[\e[38;5;245m\]\W\[\e[0m\] ${arrow} "
}
PROMPT_COMMAND=__prompt

# Tool integrations (after the prompt so zoxide appends its own hook)
eval "$(zoxide init bash)"
eval "$(fzf --bash)"
