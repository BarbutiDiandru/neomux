#!/usr/bin/env bash
# install-tmux.sh — set up tmux from the neomux repo on a fresh machine.
#
# What it does:
#   1. Installs tmux via the system package manager if missing.
#   2. Installs TPM (Tmux Plugin Manager) into ~/.config/tmux/plugins/tpm.
#   3. Backs up any existing ~/.config/tmux/*.conf and ~/.tmux.conf.
#   4. Symlinks this repo's tmux/*.conf files into ~/.config/tmux/.
#   5. Installs the plugins listed in plugins.conf non-interactively.
#
# Idempotent — safe to re-run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_DIR/tmux"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
TPM_DIR="$DEST_DIR/plugins/tpm"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n'  "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n'  "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 1. Install tmux if missing.
# -----------------------------------------------------------------------------
install_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    log "tmux already installed ($(tmux -V))"
    return
  fi

  log "tmux not found — installing"
  case "$(uname -s)" in
    Darwin)
      command -v brew >/dev/null || die "Homebrew not found. Install from https://brew.sh first."
      brew install tmux
      ;;
    Linux)
      if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y tmux
      elif command -v dnf >/dev/null; then
        sudo dnf install -y tmux
      elif command -v pacman >/dev/null; then
        sudo pacman -S --noconfirm tmux
      elif command -v zypper >/dev/null; then
        sudo zypper install -y tmux
      elif command -v apk >/dev/null; then
        sudo apk add tmux
      else
        die "No supported package manager found. Install tmux manually."
      fi
      ;;
    *)
      die "Unsupported OS: $(uname -s). Install tmux manually and re-run."
      ;;
  esac
}

# -----------------------------------------------------------------------------
# 2. Install TPM.
# -----------------------------------------------------------------------------
install_tpm() {
  if [ -d "$TPM_DIR/.git" ]; then
    log "TPM already present — pulling latest"
    git -C "$TPM_DIR" pull --ff-only --quiet || warn "TPM update skipped"
    return
  fi
  log "cloning TPM into $TPM_DIR"
  mkdir -p "$(dirname "$TPM_DIR")"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
}

# -----------------------------------------------------------------------------
# 3 + 4. Backup existing configs and symlink new ones.
# -----------------------------------------------------------------------------
link_configs() {
  mkdir -p "$DEST_DIR"

  # Warn about legacy ~/.tmux.conf — it wins over XDG if both exist.
  if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    warn "found ~/.tmux.conf — moving to ~/.tmux.conf.bak.$TIMESTAMP so XDG config takes effect"
    mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$TIMESTAMP"
  fi

  local file target
  for file in "$SRC_DIR"/*.conf; do
    target="$DEST_DIR/$(basename "$file")"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$file" ]; then
      log "symlink up to date: $target"
      continue
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      warn "backing up existing $target -> $target.bak.$TIMESTAMP"
      mv "$target" "$target.bak.$TIMESTAMP"
    fi
    log "linking $target -> $file"
    ln -s "$file" "$target"
  done
}

# -----------------------------------------------------------------------------
# 5. Install plugins non-interactively.
# -----------------------------------------------------------------------------
install_plugins() {
  local plugin_installer_script="$TPM_DIR/bin/install_plugins"
  [ -x "$plugin_installer_script" ] || die "TPM plugin_installer_script missing at $plugin_installer_script"

  log "installing tmux plugins"
  # TPM's plugin_installer_script needs a server it can talk to; start one if there isn't one.
  if ! tmux info >/dev/null 2>&1; then
    tmux start-server
    tmux new-session -d -s __neomux_bootstrap__ >/dev/null 2>&1 || true
    "$plugin_installer_script"
    tmux kill-session -t __neomux_bootstrap__ >/dev/null 2>&1 || true
  else
    "$plugin_installer_script"
  fi
}

main() {
  log "neomux tmux installer"
  log "repo: $REPO_DIR"
  log "target: $DEST_DIR"

  install_tmux
  install_tpm
  link_configs
  install_plugins

  cat <<EOF

Done.

Next:
  - Start a new tmux session:            tmux
  - Reload config from inside tmux:      prefix + r    (prefix is Ctrl-Space)
  - Update plugins later:                prefix + U
  - Save session state:                  prefix + Ctrl-s
  - Restore session state:               prefix + Ctrl-r

Edit files in $SRC_DIR — changes are live via the symlinks in $DEST_DIR.
EOF
}

main "$@"
