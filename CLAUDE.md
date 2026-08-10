# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Portable dotfiles for tmux (and eventually neovim) that get deployed onto a fresh machine by cloning this repo and running an installer. There is no build step, test suite, or package — everything here is configuration and shell.

## Commands

```bash
# Install tmux config on a new machine (idempotent — safe to re-run):
scripts/install-tmux.sh

# Reload tmux config after editing a .conf file:
#   prefix + r   (prefix is Ctrl-Space)

# Install/update/remove plugins from inside tmux:
#   prefix + I         install plugins declared in plugins.conf
#   prefix + U         update installed plugins
#   prefix + alt-u     remove plugins no longer in plugins.conf
```

## Architecture

### tmux config split

`tmux/tmux.conf` is only an entry point. It `source-file`s four sibling modules and nothing else. When editing, put the change in the module that owns that concern:

- `options.conf` — server/session/window options (prefix, colors, indexing, mouse, vi-mode). Runs first because keybindings and plugins depend on options like `mode-keys vi`.
- `keybindings.conf` — every `bind`/`unbind`. Splits use `-c "#{pane_current_path}"` so new panes inherit cwd; preserve that pattern for any new split/window binding.
- `theme.conf` — a **fallback** minimal status bar. It exists so a fresh clone (before `prefix + I` installs plugins) still looks reasonable. Catppuccin, loaded from `plugins.conf`, overwrites most of it once plugins are installed. When changing the visible theme, edit the Catppuccin block in `plugins.conf`, not this file.
- `plugins.conf` — TPM plugin list, per-plugin options, and the `run '~/.config/tmux/plugins/tpm/tpm'` bootstrap line. That `run` line must stay last.

### Deployment model — file-level symlinks

`install-tmux.sh` symlinks **each `.conf` file individually** from `tmux/` into `~/.config/tmux/`. It does **not** symlink the whole directory. This is deliberate: TPM installs plugins into `~/.config/tmux/plugins/`, and a directory symlink would put that plugin tree inside the git repo. Keep file-level linking when adding new config files.

If you add a new module file under `tmux/`, source it from `tmux.conf` — the installer's symlink loop (`for file in "$SRC_DIR"/*.conf`) picks it up automatically. Non-`.conf` files are not linked.

### Legacy config handling

The installer moves any existing `~/.tmux.conf` to `~/.tmux.conf.bak.<timestamp>` before linking. tmux prefers `~/.tmux.conf` over the XDG path when both exist, so leaving it in place would silently shadow this repo's config. Preserve that behavior in any installer changes.

### Prefix key

The prefix is `Ctrl-Space`, not `Ctrl-b` or `Ctrl-a`. `C-a` conflicts with the shell's start-of-line binding and `C-b` is awkward; `C-Space` has neither problem. If someone reports "my prefix binding X doesn't work," check they aren't still muscle-memorying the old default.

### Neovim tree

`neovim/` exists but is stale — a rewrite following the tmux pattern is planned. Do not treat its current contents as the intended design.

## Adding a plugin

1. Add `set -g @plugin '<owner>/<repo>'` to `plugins.conf` **above** the `run '.../tpm'` line.
2. Add any plugin-specific `@<option>` settings near the plugin declaration.
3. From a running tmux session: `prefix + I` — or re-run `scripts/install-tmux.sh`, which invokes TPM's headless installer.
