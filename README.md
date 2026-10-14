# Dotfiles

Configuration personnelle pour macOS et Linux, avec deux profils zsh :

| Profil | Usage | Installation |
|--------|-------|--------------|
| **full** | Machine perso / admin (macOS, Linux) | `./install.sh` : paquets (brew/apt/dnf), liens symboliques, plugins |
| **lite** | Serveur client en SSH, **sans sudo** | `./install.sh --lite` : tout dans `~/.dotfiles-lite` et `~/.local/bin` |

Les deux profils partagent le même code zsh : chaque fonctionnalité qui dépend d'un outil externe ne s'active que si cet outil est présent.

---

## Démarrage rapide

### Profil full (machine perso)

```bash
git clone git@github.com:r3glisss/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Profil lite (serveur client)

Prérequis côté serveur : `zsh`, `git`, `curl`, `tar`, accès internet (GitHub). Aucun droit admin.

```bash
git clone https://github.com/r3glisss/dotfiles.git ~/dotfiles
~/dotfiles/install.sh --lite
```

Chaque étape est affichée puis validée (voir [Mode lite](#mode-lite-serveur-client)).

Une fois le shell chargé : **`dothelp`** affiche tous les alias, fonctions et raccourcis actifs.

---

## Options d'installation

### `install.sh` (profil full)

```bash
./install.sh                  # Interactif
./install.sh --dry-run        # Simulation, aucun changement
./install.sh --force          # Non interactif (écrase, avec sauvegarde)
./install.sh --no-packages    # Sans installation de paquets
./install.sh --lite [...]     # Délègue à lite/install.sh (options ci-dessous)
./install.sh --help
```

Étapes : paquets (Homebrew + `Brewfile` sur macOS, `packages-linux.sh` sur Linux) → liens symboliques (fichiers existants sauvegardés dans `~/.dotfiles_backup_<date>`) → plugins zsh dans `~/.zsh` → TPM → vim-plug.

### `lite/install.sh` (profil lite)

```bash
lite/install.sh               # Installation / mise à jour
lite/install.sh --no-bins     # Sans eza/rg/fd/bat/fzf
lite/install.sh --uninstall   # Désinstallation
lite/install.sh --help
```

### `lite/fetch-bins.sh`

```bash
lite/fetch-bins.sh <x86_64|aarch64> <dossier> [outil...]
lite/fetch-bins.sh x86_64 ~/.local/bin rg fzf     # seulement rg et fzf
```

Télécharge les binaires Linux depuis les releases GitHub. Un fichier `.<outil>.version` est écrit dans le dossier ; un outil déjà à la bonne version n'est pas retéléchargé.

---

## Contenu du dépôt

| Chemin | Description |
|--------|-------------|
| `shell/zshrc` | Loader zsh (commun aux deux profils) |
| `shell/zsh/` | Modules zsh (voir ci-dessous) |
| `shell/plugins.list` | Plugins zsh : `<nom> <dépôt git>` |
| `shell/zprofile` | Shell de login : charge `~/.zprofile.local` |
| `lite/install.sh` | Installation du profil lite |
| `lite/fetch-bins.sh` | Téléchargement des binaires eza/rg/fd/bat/fzf |
| `install.sh` | Installation du profil full |
| `packages-linux.sh` | Paquets Linux (apt / dnf) |
| `Brewfile` | Paquets macOS |
| `editors/vimrc` | Vim (vim-plug) |
| `editors/nvim/` | Neovim (lazy.nvim) |
| `tools/tmux.conf` | Tmux (TPM) |
| `tools/starship.toml` | Prompt starship (profil full) |
| `tools/ghostty/` | Terminal Ghostty |
| `git/gitconfig`, `git/ignore` | Git |

---

## Zsh

### Ordre de chargement

```
shell/zshrc
 ├─ zsh/profile.zsh   (si présent : généré par lite/install.sh, non versionné)
 ├─ zsh/core.zsh      zsh pur : PATH utilisateur, historique, options de complétion, alias, fonctions
 ├─ zsh/macos.zsh     macOS uniquement : Homebrew, TERM, ps BSD, pmset
 ├─ zsh/tools.zsh     eza / rg / fd / bat / fzf, chacun activé seulement s'il est présent
 ├─ zsh/plugins.zsh   fpath + compinit + plugins (jamais de clone au démarrage)
 ├─ zsh/prompt.zsh    starship (profil full, si installé) sinon prompt natif
 ├─ zsh/help.zsh      commande dothelp
 ├─ zsh/full.zsh      profil full uniquement : alias AI stack, message d'accueil
 └─ ${ZDOTDIR:-$HOME}/.zshrc.local   spécificités de la machine (hors dépôt)
```

Le loader retrouve son propre dossier en résolvant le lien symbolique, il fonctionne donc aussi bien via `~/.zshrc` (full) que via `~/.dotfiles-lite/.zshrc` (lite).

### Variables

| Variable | Défaut | Rôle |
|----------|--------|------|
| `DOTFILES_PROFILE` | `full` | `full` ou `lite` (fixé par `zsh/profile.zsh` en lite) |
| `ZSH_PLUGIN_DIR` | `~/.zsh` | Dossier des plugins (`~/.dotfiles-lite/plugins` en lite) |
| `ZSH_CFG_DIR` | calculé | Dossier `shell/zsh` du dépôt |
| `HISTFILE` | `${ZDOTDIR:-$HOME}/.zsh_history` | Historique (50 000 en mémoire, 10 000 sur disque, partagé entre sessions) |

### Fichiers locaux (hors dépôt)

Tout ce qui est propre à une machine (PATH ajoutés par des installeurs, SDK, `JAVA_HOME`…) va dans :

- `~/.zshrc.local` : chargé en dernier par `zshrc`
- `~/.zprofile.local` : chargé par `zprofile` (shells de login)

En lite, l'équivalent est `~/.dotfiles-lite/.zshrc.local`. Le dépôt ne contient aucun chemin en dur.

> Les installeurs (bun, gcloud…) ajoutent souvent leurs lignes à `~/.zshrc`, qui est un lien vers le dépôt : les déplacer dans `~/.zshrc.local`.

### Aide intégrée : `dothelp`

```bash
dothelp             # tout
dothelp <section>   # info base ls git search proc func keys plugins macos full
dothelp list        # liste des sections
```

N'affiche que ce qui est réellement actif (outils présents, profil, OS). La section `info` montre le profil, les chemins utilisés et l'emplacement de chaque outil. Complétion sur les noms de sections.

### Alias

**Base & navigation**

| Alias | Commande |
|-------|----------|
| `c` | `clear` |
| `..` / `...` / `....` | remonter de 1 / 2 / 3 dossiers |
| `groot` | racine du dépôt git |
| `z <motif>` | saut vers un dossier fréquent (plugin zsh-z) |
| `python` | `python3` |
| `cp` / `mv` / `rm` | avec confirmation (`-i`) |
| `grep` | `grep --color=auto` |

**Listing** : avec eza si présent, sinon `ls` natif

| Alias | eza | Sans eza |
|-------|-----|----------|
| `ls` | dossiers en premier, icônes | `ls --color=auto --group-directories-first` (GNU) ou `ls -G` (BSD) |
| `ll` / `la` | liste longue (+ cachés), statut git | `ls -lh` / `ls -lah` |
| `l.` | fichiers cachés | fichiers cachés |
| `lt` | arbre complet | – |
| `tree` / `ltree` | arbre 3 niveaux / long 2 niveaux | – |
| `lsf` / `lsd` | un par ligne / dossiers seulement | – |
| `lss` / `lst` | tri taille / date | – |

**Git**

| Alias | Commande |
|-------|----------|
| `g` | `git` |
| `ga` / `gaa` / `gaddup` | `add` / `add .` / `add -u` |
| `gcommit` / `gca` | `commit -m` / `commit -am` |
| `gst` / `gd` / `gf` | `status` / `diff` / `fetch` |
| `gb` / `gbd` / `gco` | `branch` / `branch -d` / `checkout` |
| `gpull` / `gpush` / `gcl` | `pull` / `push` / `clone` |
| `ggraph` | log graphique de toutes les branches |

**Recherche** : avec rg / fzf si présents

| Alias | Description | Requiert |
|-------|-------------|----------|
| `rgi` | rg insensible à la casse | rg |
| `rgf` | fichiers dont le nom correspond | rg |
| `rgl` / `rgc` | fichiers contenant le motif / nombre de matchs | rg |
| `ff` | fzf avec preview | fzf |
| `fv` | choisir un fichier, l'ouvrir dans vim | fzf |
| `fe` | choisir un fichier, l'ouvrir dans VS Code | fzf, code |
| `fcd` | cd fuzzy dans un sous-dossier | fzf |

Les previews utilisent bat (ou `head`) pour les fichiers et eza (ou `ls`) pour les dossiers. Sur Debian/Ubuntu, `batcat` et `fdfind` sont détectés.

**Processus**

| Alias | Description |
|-------|-------------|
| `psa` | tous les processus (`ps auxf` Linux, `ps aux` macOS) |
| `psgrep <motif>` | chercher un processus |
| `psmem` / `pscpu` | tri par mémoire / CPU |

**Profil full**

| Alias | Description |
|-------|-------------|
| `ccusage` | usage Claude Code en direct (`npx`) |
| `claude-serena` | serveur MCP serena sur le dossier courant |

### Fonctions

| Fonction | Description | Requiert |
|----------|-------------|----------|
| `extract <archive>` | tar, gz, bz2, xz, zip, rar, 7z… | – |
| `bookmark <nom>` | ajoute le dossier courant à `~/.bookmarks` | – |
| `goto` | aller à un bookmark | fzf |
| `fzf_edit [requête]` | ouvrir un fichier dans `$EDITOR` | fzf |
| `fzf_cd` | cd fuzzy | fzf |
| `fzf_history [requête]` | rappeler une commande de l'historique | fzf |
| `fzf_git_branch` | checkout d'une branche | fzf |
| `fzf_kill [signal]` | tuer des processus (défaut : 9) | fzf |
| `enable_shutdown` / `disable_shutdown` | extinction auto à 3h (sudo, `pmset`) | macOS |
| `dothelp [section]` | aide | – |

### Raccourcis clavier

| Touche | Action | Requiert |
|--------|--------|----------|
| `Ctrl-T` | insérer un fichier | fzf |
| `Ctrl-R` | historique (`Ctrl-Y` copie la commande, macOS) | fzf |
| `Alt-C` | cd dans un sous-dossier | fzf |
| `Ctrl-E` | `fzf_edit` | fzf |
| `Ctrl-G` | `fzf_git_branch` | fzf |
| `Ctrl-K` | `fzf_kill` | fzf |
| `↑` / `↓` | historique filtré par le texte tapé | history-substring-search |
| `k` / `j` (mode vi normal) | idem | history-substring-search |
| `→` / `Fin` | accepter la suggestion grisée | autosuggestions |
| `Tab` | complétion en menu, insensible à la casse | – |

Dans fzf : `Ctrl-/` affiche/masque la preview, `Ctrl-U` / `Ctrl-D` font défiler la preview.

### Plugins

Listés dans `shell/plugins.list`. Tous en zsh pur : pas de compilation, rien à installer au niveau système.

| Plugin | Rôle |
|--------|------|
| zsh-completions | complétions supplémentaires (ajouté au `fpath` avant `compinit`) |
| zsh-autosuggestions | suggestions grisées issues de l'historique et de la complétion |
| zsh-history-substring-search | `↑` / `↓` filtrés |
| zsh-z | `z <motif>` : saut vers les dossiers fréquents |
| zsh-syntax-highlighting | coloration de la ligne de commande (chargé en dernier) |

Ils sont clonés par `install.sh` (`~/.zsh`) ou `lite/install.sh` (`~/.dotfiles-lite/plugins`). Le shell ne clone jamais rien au démarrage. Pour ajouter un plugin : une ligne dans `plugins.list` + son `source` dans `zsh/plugins.zsh`.

`compinit` reconstruit le cache de complétion (`.zcompdump`) au plus une fois par 24 h, sinon chargement rapide (`-C`).

### Prompt

- **full** : starship (`tools/starship.toml`) s'il est installé.
- **lite** (ou sans starship) : prompt natif, `user@host dossier branche ❯`. `user@host` est en rouge si root, `❯` est rouge si la dernière commande a échoué. La branche git (et l'action en cours : rebase, merge…) vient de `vcs_info`.

---

## Mode lite (serveur client)

### Principe

- **Aucun sudo, aucun paquet système.** Le dépôt est cloné en HTTPS (public, pas de clé nécessaire).
- **Le `.zshrc` du client n'est pas modifié** : le profil passe par `ZDOTDIR=~/.dotfiles-lite`. Les `~/.zprofile`, `~/.zlogin` et `~/.zlogout` du client restent chargés.
- **Chaque étape est validée** : `o` exécuter, `n` passer, `q` quitter.

### Étapes de `lite/install.sh`

0. **Détection** : OS, architecture, shell de login, présence de zsh/git/curl/tar (arrêt si l'un manque). Les outils déjà fournis par le système sont conservés ; seuls les absents sont proposés.
1. **Plugins zsh** : `git clone --depth=1` dans `~/.dotfiles-lite/plugins`, ou `git pull` s'ils existent déjà.
2. **Configuration** : `~/.dotfiles-lite/.zshrc` → lien vers `~/dotfiles/shell/zshrc`, shims `.zprofile/.zlogin/.zlogout`, génération de `shell/zsh/profile.zsh` (`DOTFILES_PROFILE=lite`).
3. **Binaires** : téléchargement dans `~/.local/bin` des outils absents (liste conservée dans `~/.dotfiles-lite/bins.installed`).
4. **Activation au login** : ajout d'un bloc balisé, le fichier d'origine est sauvegardé une seule fois en `*.bak-dotfiles-lite` :
   - shell de login **zsh** → `~/.zshenv` :
     ```zsh
     # >>> dotfiles-lite >>>
     [[ -o interactive && ! -f $HOME/.dotfiles-lite/disabled ]] && export ZDOTDIR="$HOME/.dotfiles-lite"
     # <<< dotfiles-lite <<<
     ```
   - shell de login **bash** (pas besoin de `chsh`) → `~/.bashrc` :
     ```bash
     # >>> dotfiles-lite >>>
     if [[ $- == *i* && -z $ZSH_VERSION && ! -f $HOME/.dotfiles-lite/disabled ]] && command -v zsh >/dev/null 2>&1; then
         export ZDOTDIR="$HOME/.dotfiles-lite"
         exec zsh
     fi
     # <<< dotfiles-lite <<<
     ```
   Si cette étape est passée : lancer à la main avec `ZDOTDIR=~/.dotfiles-lite zsh`.
5. **Test** : lance un zsh interactif avec le profil et affiche le profil, l'alias `ls` et l'emplacement des outils.

### Arborescence côté serveur

```
~/dotfiles/                       clone du dépôt (config zsh lue directement ici)
  shell/zsh/profile.zsh           généré, non versionné
~/.dotfiles-lite/                 ZDOTDIR
  .zshrc -> ~/dotfiles/shell/zshrc
  .zprofile .zlogin .zlogout      chargent ceux du client
  .zsh_history .zcompdump
  .zshrc.local                    réglages propres à ce client (optionnel)
  plugins/                        plugins zsh (clones git)
  bins.installed                  binaires installés par le script
  disabled                        (optionnel) désactive le profil
~/.local/bin/                     eza rg fd bat fzf + .<outil>.version
```

### Binaires optionnels

Versions figées dans `lite/fetch-bins.sh` pour qu'une installation soit reproductible :

| Outil | Version | x86_64 | aarch64 |
|-------|---------|--------|---------|
| rg | 15.2.0 | musl statique | musl statique |
| fd | 10.5.0 | musl statique | musl statique |
| bat | 0.26.1 | musl statique | musl statique |
| eza | 0.23.5 | musl statique | **glibc** (pas de build musl publié) |
| fzf | 0.74.5 | Go statique | Go statique |

Les binaires statiques n'ont aucune dépendance et fonctionnent sur toute distribution Linux. Pour changer de version : modifier la variable en tête de `fetch-bins.sh`, puis relancer l'installation.

### Opérations courantes

| Besoin | Commande |
|--------|----------|
| Mettre à jour (config, plugins, binaires) | `cd ~/dotfiles && git pull && lite/install.sh` |
| Désactiver temporairement | `touch ~/.dotfiles-lite/disabled` (réactiver : `rm` du fichier) |
| Réglage propre à un client | éditer `~/.dotfiles-lite/.zshrc.local` |
| Vérifier l'état | `dothelp info` |
| Désinstaller | `~/dotfiles/lite/install.sh --uninstall` |

La relance de `lite/install.sh` est idempotente : le bloc de login n'est jamais dupliqué et les binaires à jour ne sont pas retéléchargés.

### Désinstallation

`--uninstall` (chaque étape est validée) :
1. retire les blocs de `~/.zshenv` et `~/.bashrc` ;
2. supprime les binaires listés dans `bins.installed` ;
3. supprime `~/.dotfiles-lite` (**historique et `.zshrc.local` compris**) et `profile.zsh`.

Restent à supprimer à la main si besoin : `~/dotfiles` et les sauvegardes `*.bak-dotfiles-lite`.

---

## Liens symboliques (profil full)

```
~/.zshrc                -> ~/dotfiles/shell/zshrc
~/.zprofile             -> ~/dotfiles/shell/zprofile
~/.vimrc                -> ~/dotfiles/editors/vimrc
~/.config/nvim          -> ~/dotfiles/editors/nvim
~/.tmux.conf            -> ~/dotfiles/tools/tmux.conf
~/.config/starship.toml -> ~/dotfiles/tools/starship.toml
~/.config/ghostty       -> ~/dotfiles/tools/ghostty
~/.gitconfig            -> ~/dotfiles/git/gitconfig
~/.config/git/ignore    -> ~/dotfiles/git/ignore
```

## Après installation (profil full)

1. Redémarrer le terminal ou `source ~/.zshrc`
2. Tmux : `prefix + I` pour installer les plugins
3. Vim : `:PlugInstall`
4. Neovim : lazy.nvim s'installe au premier lancement

## Raccourcis tmux & éditeurs

### Tmux (préfixe : `Ctrl-a`)

| Touche | Action |
|--------|--------|
| `prefix + I` | installer les plugins (TPM) |
| `prefix + r` | recharger la config |
| `prefix + \|` / `prefix + -` | split vertical / horizontal |
| `prefix + h/j/k/l` | naviguer entre panneaux |
| `prefix + H/J/K/L` | redimensionner |
| `prefix + m` | zoom du panneau |
| `prefix + x` / `X` | fermer panneau / fenêtre |
| `prefix + c` | nouvelle fenêtre (dossier courant) |
| `prefix + Ctrl-h/l`, `Tab` | fenêtre précédente / suivante / dernière |
| `prefix + Escape` | mode copie (`v` sélection, `y` copie) |
| `prefix + s` | synchroniser les panneaux |
| `prefix + f` / `g` / `t` | popup fzf / lazygit / htop |

### Vim / Neovim

Voir `editors/vimrc` et `editors/nvim/`.

## Prérequis

| | full | lite |
|--|------|------|
| OS | macOS, Linux (apt/dnf) | Linux x86_64 / aarch64 |
| Droits | sudo (paquets) | aucun |
| Outils | git, zsh, curl (Homebrew auto-installé sur macOS) | zsh, git, curl, tar |

## Mise à jour (profil full)

```bash
cd ~/dotfiles
git pull
./install.sh --force
```

## Limites connues

- `tools/tmux.conf` utilise `default-terminal "xterm-ghostty"`, une terminfo absente de la plupart des serveurs : il n'y a pas encore de tmux lite.
- Les binaires téléchargés par `fetch-bins.sh` ne sont pas vérifiés par checksum.
- `eza` aarch64 dépend de la glibc du serveur.
