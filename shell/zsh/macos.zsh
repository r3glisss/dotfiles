# --------------------------------------------------------------------------- #
#                         SPÉCIFIQUE macOS (darwin)
# --------------------------------------------------------------------------- #
# Homebrew (avant tools.zsh : eza, fzf… viennent de là)
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Terminal type (xterm-ghostty inconnu des serveurs distants via ssh)
export TERM="xterm-256color"

# ps BSD : pas d'option f
alias psa="ps aux"
alias psmem='ps aux | sort -nr -k 4'
alias pscpu='ps aux | sort -nr -k 3'

# System shutdown
enable_shutdown() {
  echo "Activation de l'extinction automatique à 3h du matin tous les jours..."
  sudo pmset repeat shutdown MTWRFSU 03:00:00
  echo "Extinction programmée activée."
}

# Disable system shutdown
disable_shutdown() {
  echo "Désactivation de l'extinction automatique programmée..."
  sudo pmset repeat cancel
  echo "Extinction programmée désactivée."
}
