# Dotfiles

Personal configuration files for macOS and Linux.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Installation Options

```bash
./install.sh              # Interactive install
./install.sh --dry-run    # Preview changes without applying
./install.sh --force      # Non-interactive (overwrites existing)
./install.sh --no-packages # Skip package installation
```

## What's Included

| Config | Description |
|--------|-------------|
| `shell/zshrc` | Zsh configuration with aliases and functions |
| `shell/zprofile` | Zsh profile (login shell) |
| `editors/vimrc` | Vim configuration with vim-plug |
| `editors/nvim/` | Neovim config (LazyVim-based) |
| `tools/tmux.conf` | Tmux config with TPM plugins |
| `tools/starship.toml` | Starship prompt theme |
| `tools/ghostty/` | Ghostty terminal config |
| `git/gitconfig` | Git configuration |
| `git/ignore` | Global gitignore |

## Symlinks Created

```
~/.zshrc           -> ~/dotfiles/shell/zshrc
~/.zprofile        -> ~/dotfiles/shell/zprofile
~/.vimrc           -> ~/dotfiles/editors/vimrc
~/.config/nvim     -> ~/dotfiles/editors/nvim
~/.tmux.conf       -> ~/dotfiles/tools/tmux.conf
~/.config/starship.toml -> ~/dotfiles/tools/starship.toml
~/.config/ghostty  -> ~/dotfiles/tools/ghostty
~/.gitconfig       -> ~/dotfiles/git/gitconfig
~/.config/git/ignore -> ~/dotfiles/git/ignore
```

## Post-Installation

1. **Restart terminal** or run `source ~/.zshrc`
2. **Tmux plugins**: Open tmux, press `prefix + I` to install plugins
3. **Vim plugins**: Open vim, run `:PlugInstall`
4. **Neovim**: Lazy.nvim bootstraps automatically on first launch

## Key Bindings

### Tmux (prefix: Ctrl-a)
- `prefix + I` - Install plugins
- `prefix + |` - Split vertical
- `prefix + -` - Split horizontal
- `prefix + h/j/k/l` - Navigate panes

### Vim/Neovim
- `<leader>` is typically `Space` or `\`
- See individual config files for details

## Requirements

- macOS: Homebrew (auto-installed)
- Linux: apt (Debian/Ubuntu) or dnf (Fedora)
- Git
- Zsh

## Updating

Pull changes and re-run install:

```bash
cd ~/dotfiles
git pull
./install.sh --force
```
