#!/bin/bash
# nvim_tmux_setup-fedora.sh — LazyVim + Tmux AZERTY fr_FR + ShellCheck
# Adapté pour Fedora depuis la version Ubuntu
# Usage : sudo bash nvim_tmux_setup-fedora.sh

# Pas de set -e : on gère les erreurs manuellement pour ne pas bloquer

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERR ]${NC} $1"; }
print_step() { echo -e "\n${BLUE}==>${NC} $1"; }

if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME="/home/$REAL_USER"
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi
print_info "Installation pour : $REAL_USER ($REAL_HOME)"

# ============================================================
# 1. DEPENDANCES
# ============================================================
print_step "Installation des dependances systeme (dnf)..."

# Installation paquet par paquet pour éviter l'échec global (dnf5 sur Fedora 41+)
dnf_install_safe() {
    for pkg in "$@"; do
        if dnf list --installed "$pkg" &>/dev/null; then
            print_info "$pkg : déjà installé, ignoré."
        else
            print_info "Installation de $pkg..."
            dnf install -y "$pkg" 2>/dev/null || print_warning "$pkg : non disponible, ignoré."
        fi
    done
}

dnf_install_safe \
    tmux git curl wget ripgrep fd-find fzf tree \
    nodejs npm python3 python3-pip python3-virtualenv \
    make gcc gcc-c++ unzip xclip xsel

# python3-pynvim : nom variable selon version Fedora
print_info "Installation de python3-pynvim / pynvim..."
dnf install -y python3-pynvim 2>/dev/null || \
    pip3 install pynvim --break-system-packages 2>/dev/null || \
    pip3 install pynvim 2>/dev/null || \
    print_warning "pynvim non installé (non bloquant)."

# ---- NEOVIM ----
# 1. repo Fedora standard
if ! command -v nvim &>/dev/null; then
    print_info "Installation neovim depuis les repos Fedora..."
    dnf install -y neovim 2>/dev/null || true
fi
# 2. COPR neovim-nightly
if ! command -v nvim &>/dev/null; then
    print_warning "neovim absent des repos standard, tentative COPR..."
    dnf copr enable -y agriffis/neovim-nightly 2>/dev/null || true
    dnf install -y neovim 2>/dev/null || true
fi
# 3. Tarball officiel GitHub (toujours disponible)
if ! command -v nvim &>/dev/null; then
    print_warning "Fallback : installation Neovim via tarball officiel GitHub..."
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
        -o /tmp/nvim.tar.gz
    mkdir -p /opt
    tar -xzf /tmp/nvim.tar.gz -C /opt/
    ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim.tar.gz
    print_info "Neovim installé → /usr/local/bin/nvim"
fi

if command -v nvim &>/dev/null; then
    print_info "Neovim OK : $(nvim --version | head -1)"
else
    print_error "Neovim introuvable après toutes les tentatives. Abandon."
    exit 1
fi

# ============================================================
# 2. SHELLCHECK
# ============================================================
print_info "Installation de ShellCheck depuis GitHub..."
wget -q https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz
tar -xf shellcheck-v0.10.0.linux.x86_64.tar.xz
cp shellcheck-v0.10.0/shellcheck /usr/local/bin/
rm -rf shellcheck-v0.10.0*
chmod +x /usr/local/bin/shellcheck
print_info "ShellCheck installé"

npm install -g neovim 2>/dev/null || true

# ============================================================
# 3. LAZYVIM
# ============================================================
print_step "Installation de LazyVim..."
NVIM_CONFIG="${REAL_HOME}/.config/nvim"
NVIM_DATA="${REAL_HOME}/.local/share/nvim"
NVIM_CACHE="${REAL_HOME}/.cache/nvim"
NVIM_STATE="${REAL_HOME}/.local/state/nvim"

if [ -d "$NVIM_CONFIG" ]; then
    print_warning "Backup de l'ancienne config -> ${NVIM_CONFIG}.bak"
    mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
fi
for d in "$NVIM_DATA" "$NVIM_CACHE" "$NVIM_STATE"; do
    if [ -d "$d" ]; then
        mv "$d" "${d}.bak" 2>/dev/null || true
    fi
done

sudo -u "$REAL_USER" git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
rm -rf "$NVIM_CONFIG/.git"

# ============================================================
# 4. CONFIG LAZYVIM PERSONNALISEE
# ============================================================
print_step "Ecriture de la config LazyVim..."
sudo -u "$REAL_USER" mkdir -p "$NVIM_CONFIG/lua/config"
sudo -u "$REAL_USER" mkdir -p "$NVIM_CONFIG/lua/plugins"

# options.lua
cat >"$NVIM_CONFIG/lua/config/options.lua" <<'EOF'
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.tabstop        = 4
vim.opt.softtabstop    = 4
vim.opt.shiftwidth     = 4
vim.opt.expandtab      = true
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.scrolloff      = 8
vim.opt.sidescrolloff  = 8
vim.opt.signcolumn     = "yes"
vim.opt.termguicolors  = true
vim.opt.mouse          = "a"
vim.opt.clipboard      = "unnamedplus"
vim.opt.swapfile       = false
vim.opt.undofile       = true
vim.opt.encoding       = "utf-8"
vim.opt.fileencoding   = "utf-8"
vim.opt.updatetime     = 200
vim.opt.timeoutlen     = 300
EOF

# keymaps.lua
cat >"$NVIM_CONFIG/lua/config/keymaps.lua" <<'EOF'
local map = vim.keymap.set

-- Sauvegarde / Quitter
map("n", "<C-s>", "<cmd>w<CR>",      { desc = "Sauvegarder" })
map("i", "<C-s>", "<Esc><cmd>w<CR>", { desc = "Sauvegarder (insert)" })
map("n", "<C-q>", "<cmd>q<CR>",      { desc = "Quitter" })

-- Navigation splits — Ctrl+Fleches
map("n", "<C-Left>",  "<C-w>h", { desc = "Split gauche" })
map("n", "<C-Down>",  "<C-w>j", { desc = "Split bas" })
map("n", "<C-Up>",    "<C-w>k", { desc = "Split haut" })
map("n", "<C-Right>", "<C-w>l", { desc = "Split droite" })

-- Resize splits — Alt+Fleches
map("n", "<A-Left>",  "<C-w><", { desc = "Reduire largeur" })
map("n", "<A-Right>", "<C-w>>", { desc = "Augmenter largeur" })
map("n", "<A-Up>",    "<C-w>+", { desc = "Augmenter hauteur" })
map("n", "<A-Down>",  "<C-w>-", { desc = "Reduire hauteur" })

-- Buffers
map("n", "<Tab>",      "<cmd>bnext<CR>",     { desc = "Buffer suivant" })
map("n", "<S-Tab>",    "<cmd>bprevious<CR>", { desc = "Buffer precedent" })
map("n", "<leader>bd", "<cmd>bdelete<CR>",   { desc = "Fermer buffer" })

-- Deplacer lignes (visuel)
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Ligne bas" })
map("v", "<A-Up>",   ":m '<-2<CR>gv=gv", { desc = "Ligne haut" })

-- Indentation
map("v", "<", "<gv", { desc = "Desindenter" })
map("v", ">", ">gv", { desc = "Indenter" })

-- Recherche centree
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Diagnostic
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Diagnostic precedent" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Diagnostic suivant" })
EOF

# plugins/extras.lua
cat >"$NVIM_CONFIG/lua/plugins/extras.lua" <<'EOF'
return {

  { "folke/tokyonight.nvim", opts = { style = "night" } },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        ts_ls   = {},
        lua_ls  = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        bashls = {
          settings = {
            bashIde = {
              shellcheckPath = "/usr/local/bin/shellcheck",
              enableShellCheck = true,
              externalSources = true,
            }
          }
        },
        html   = {},
        cssls  = {},
        jsonls = {},
        yamlls = {},
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "python", "javascript", "typescript",
        "c", "cpp", "go", "rust", "bash",
        "html", "css", "json", "yaml", "toml",
        "markdown", "markdown_inline",
      },
    },
  },

  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  { "folke/todo-comments.nvim", opts = { signs = true } },
  { "folke/zen-mode.nvim", cmd = "ZenMode" },
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  {
    "ThePrimeagen/harpoon",
    branch       = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end,                                 desc = "Harpoon: ajouter"   },
      { "<C-e>",      function() local h=require("harpoon"); h.ui:toggle_quick_menu(h:list()) end,    desc = "Harpoon: menu"      },
      { "<leader>h1", function() require("harpoon"):list():select(1) end,                             desc = "Harpoon: fichier 1" },
      { "<leader>h2", function() require("harpoon"):list():select(2) end,                             desc = "Harpoon: fichier 2" },
      { "<leader>h3", function() require("harpoon"):list():select(3) end,                             desc = "Harpoon: fichier 3" },
      { "<leader>h4", function() require("harpoon"):list():select(4) end,                             desc = "Harpoon: fichier 4" },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "+" },
        change       = { text = "~" },
        delete       = { text = "-" },
        topdelete    = { text = "-" },
        changedelete = { text = "~" },
      },
    },
  },
}
EOF

# ============================================================
# 5. PREMIER LANCEMENT LAZYVIM
# ============================================================
print_step "Installation des plugins LazyVim (headless)..."
chown -R "$REAL_USER:$REAL_USER" "$NVIM_CONFIG"
sudo -u "$REAL_USER" nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true
print_info "Plugins installes."

# ============================================================
# 6. TMUX CONFIG AZERTY
# ============================================================
print_step "Configuration Tmux (AZERTY)..."

cat >"${REAL_HOME}/.tmux.conf" <<'TMUXEOF'
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -sg escape-time 10
set -g focus-events on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g mouse on
set -g history-limit 10000

set -g status-position bottom
set -g status-bg "#1a1b26"
set -g status-fg "#a9b1d6"
set -g status-left-length 40
set -g status-right-length 60
set -g status-left  "#[fg=#7aa2f7,bold] #S #[fg=#3b4261]| "
set -g status-right "#[fg=#3b4261]| #[fg=#9ece6a] %H:%M #[fg=#3b4261]| #[fg=#7dcfff] %d/%m/%Y "
set -g window-status-format         "#[fg=#565f89] #I:#W "
set -g window-status-current-format "#[fg=#7aa2f7,bold,bg=#16161e] #I:#W #[default]"
set -g pane-border-style            "fg=#3b4261"
set -g pane-active-border-style     "fg=#7aa2f7"
set -g message-style                "fg=#7aa2f7,bg=#1a1b26"

unbind C-b
set -g prefix C-a
bind C-a send-prefix
bind r source-file ~/.tmux.conf \; display "tmux.conf rechargé"

unbind '"'
unbind %
bind v split-window -h -c "#{pane_current_path}"
bind b split-window -v -c "#{pane_current_path}"
bind | split-window -h -c "#{pane_current_path}"
bind = split-window -v -c "#{pane_current_path}"

bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D
bind Left  select-pane -L
bind Right select-pane -R
bind Up    select-pane -U
bind Down  select-pane -D
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind -r C-Left  resize-pane -L 3
bind -r C-Right resize-pane -R 3
bind -r C-Up    resize-pane -U 3
bind -r C-Down  resize-pane -D 3
bind -r S-Left  resize-pane -L 10
bind -r S-Right resize-pane -R 10
bind -r S-Up    resize-pane -U 5
bind -r S-Down  resize-pane -D 5

bind c   new-window -c "#{pane_current_path}"
bind x   kill-pane
bind X   kill-window
bind Tab  next-window
bind BTab previous-window

bind s choose-session
bind d detach
bind N new-session

setw -g mode-keys vi
bind [ copy-mode
bind -T copy-mode-vi v      send-keys -X begin-selection
bind -T copy-mode-vi C-v    send-keys -X rectangle-toggle
bind -T copy-mode-vi y      send-keys -X copy-selection-and-cancel
bind -T copy-mode-vi q      send-keys -X cancel
bind -T copy-mode-vi Escape send-keys -X cancel
bind -T copy-mode-vi Left   send-keys -X cursor-left
bind -T copy-mode-vi Right  send-keys -X cursor-right
bind -T copy-mode-vi Up     send-keys -X cursor-up
bind -T copy-mode-vi Down   send-keys -X cursor-down

bind p run "xclip -o -sel clip 2>/dev/null | tmux load-buffer - && tmux paste-buffer || tmux paste-buffer"

bind W run-shell 'tmux display-popup -E -w 74 -h 38 -x C -y C "bash ~/.tmux-welcome.sh"'
set-hook -g session-created 'run-shell "sleep 0.3 && tmux display-popup -E -w 74 -h 38 -x C -y C \"bash ~/.tmux-welcome.sh\""'

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

if-shell "test -f ~/.tmux/plugins/tpm/tpm" "run '~/.tmux/plugins/tpm/tpm'"
TMUXEOF

cat >"${REAL_HOME}/.tmux-welcome.sh" <<'WELCOMEOF'
#!/bin/bash
C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'
D='\033[2;37m'; B='\033[1m';    R='\033[0m'
clear
printf "${C}${B}"
printf "  ████████╗███╗   ███╗██╗   ██╗██╗  ██╗\n"
printf "     ██╔══╝████╗ ████║██║   ██║╚██╗██╔╝\n"
printf "     ██║   ██╔████╔██║██║   ██║ ╚███╔╝ \n"
printf "     ██║   ██║╚██╔╝██║██║   ██║ ██╔██╗ \n"
printf "     ██║   ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗\n"
printf "     ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝\n"
printf "${R}\n"
printf "${D}  ──────────────────────────────────────────────────────${R}\n"
printf "  ${Y}${B}PREFIX : Ctrl+A${R}\n"
printf "${D}  ──────────────────────────────────────────────────────${R}\n\n"
printf "${G}${B}  SPLITS${R}\n"
printf "  ${C}Ctrl+A v${R}   split vertical   (cote a cote)\n"
printf "  ${C}Ctrl+A b${R}   split horizontal (haut / bas)\n\n"
printf "${G}${B}  NAVIGATION panes${R}  ${D}(3 methodes)${R}\n"
printf "  ${C}Alt + Fleches${R}            sans prefix  ${D}[le plus rapide]${R}\n"
printf "  ${C}Ctrl+A + Fleches${R}         avec prefix\n"
printf "  ${C}Ctrl+A + h j k l${R}         vim-style\n\n"
printf "${G}${B}  RESIZE panes${R}\n"
printf "  ${C}Ctrl+A + Ctrl + Fleches${R}  +3  (repetable)\n"
printf "  ${C}Ctrl+A + Maj  + Fleches${R}  +10 (grand pas)\n\n"
printf "${G}${B}  FENETRES${R}\n"
printf "  ${C}Ctrl+A c${R}    nouvelle fenetre\n"
printf "  ${C}Ctrl+A Tab${R}  fenetre suivante\n"
printf "  ${C}Ctrl+A 1-9${R}  aller a la fenetre N\n"
printf "  ${C}Ctrl+A x${R}    fermer pane    ${C}Ctrl+A X${R}  fermer fenetre\n\n"
printf "${G}${B}  SESSIONS${R}\n"
printf "  ${C}Ctrl+A s${R}   choisir    ${C}Ctrl+A d${R}  detacher\n"
printf "  ${C}Ctrl+A N${R}   nouvelle session\n\n"
printf "${G}${B}  COPY MODE${R}\n"
printf "  ${C}Ctrl+A [${R}   entrer      Fleches ou hjkl pour naviguer\n"
printf "  ${C}v${R} selectionner    ${C}y${R} copier    ${C}q${R} quitter\n\n"
printf "${G}${B}  DIVERS${R}\n"
printf "  ${C}Ctrl+A r${R}   recharger tmux.conf\n"
printf "  ${C}Ctrl+A W${R}   reafficher cette aide\n"
printf "  ${C}Ctrl+A p${R}   coller depuis clipboard systeme\n\n"
printf "${D}  ──────────────────────────────────────────────────────${R}\n"
printf "  ${D}Appuie sur une touche pour fermer...${R}\n"
read -n 1 -s
WELCOMEOF
chmod +x "${REAL_HOME}/.tmux-welcome.sh"

# ============================================================
# 7. TPM
# ============================================================
print_step "Installation de TPM..."
if [ ! -d "${REAL_HOME}/.tmux/plugins/tpm" ]; then
    sudo -u "$REAL_USER" git clone https://github.com/tmux-plugins/tpm \
        "${REAL_HOME}/.tmux/plugins/tpm"
fi
sudo -u "$REAL_USER" \
    "${REAL_HOME}/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true

# ============================================================
# 8. ALIAS
# ============================================================
print_step "Configuration des alias..."
[ -f "${REAL_HOME}/.zshrc" ] && ALIAS_FILE="${REAL_HOME}/.zsh_aliases" ||
    ALIAS_FILE="${REAL_HOME}/.bash_aliases"

if ! grep -q "# === Alias NVIM/TMUX ===" "$ALIAS_FILE" 2>/dev/null; then
    cat >>"$ALIAS_FILE" <<'ALIASEOF'
# === Alias NVIM/TMUX ===
alias v='nvim'
alias vim='nvim'
alias vi='nvim'
alias sv='sudo -E nvim'
alias vimconfig='nvim ~/.config/nvim'
alias t='tmux'
alias tn='tmux new-session -s'
alias ta='tmux attach -t'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tks='tmux kill-server'
alias vtm='tmux new-window nvim'
alias c='clear'
alias reload='source ~/.bashrc'
alias h='history | grep'
alias ff='find . -type f | fzf --preview "cat {}"'
alias gco='git checkout $(git branch | fzf)'
alias gd='git diff $(git status -s | fzf | cut -c4-)'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"'
nvim-tmux() {
    local s="${1:-dev}"
    tmux has-session -t "$s" 2>/dev/null \
        && tmux attach -t "$s" \
        || tmux new-session -s "$s" nvim
}
svim()    { sudo -E nvim "$@"; }
project() { cd "$1" && nvim .; }
ALIASEOF
fi
! grep -q "bash_aliases" "${REAL_HOME}/.bashrc" 2>/dev/null &&
    echo -e "\n[ -f ~/.bash_aliases ] && source ~/.bash_aliases" >>"${REAL_HOME}/.bashrc"

# ============================================================
# 9. SCRIPT install-lsp-servers
# ============================================================
cat >/usr/local/bin/install-lsp-servers <<'LSPEOF'
#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC}  $1"; }

echo "=== Installation des serveurs LSP ==="

# --- Python LSP ---
echo "→ Python LSP..."
pip install \
    python-lsp-server \
    pylsp-mypy \
    python-lsp-black \
    python-lsp-ruff \
    --break-system-packages 2>/dev/null \
|| pip install \
    python-lsp-server \
    pylsp-mypy \
    python-lsp-black \
    python-lsp-ruff \
|| warn "Certains paquets Python LSP non installés."
ok "Python LSP"

# --- TypeScript / JS ---
echo "→ TypeScript LSP..."
npm install -g typescript typescript-language-server && ok "typescript-language-server" || warn "typescript-language-server échoué"

# --- HTML / CSS / JSON ---
echo "→ HTML/CSS/JSON LSP..."
npm install -g vscode-langservers-extracted && ok "vscode-langservers-extracted" || warn "vscode-langservers-extracted échoué"

# --- Bash ---
echo "→ Bash LSP..."
npm install -g bash-language-server && ok "bash-language-server" || warn "bash-language-server échoué"

# --- YAML ---
echo "→ YAML LSP..."
npm install -g yaml-language-server && ok "yaml-language-server" || warn "yaml-language-server échoué"

# --- Lua ---
echo "→ Lua LSP..."
# lua-language-server n'est pas dans les repos Fedora standard
# On le télécharge depuis GitHub releases
LUA_LS_VERSION="3.13.9"
LUA_LS_URL="https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/lua-language-server-${LUA_LS_VERSION}-linux-x64.tar.gz"
LUA_LS_DIR="/opt/lua-language-server"

if command -v lua-language-server &>/dev/null; then
    ok "lua-language-server déjà installé."
else
    mkdir -p "$LUA_LS_DIR"
    curl -fsSL "$LUA_LS_URL" -o /tmp/lua-ls.tar.gz && \
    tar -xzf /tmp/lua-ls.tar.gz -C "$LUA_LS_DIR" && \
    rm -f /tmp/lua-ls.tar.gz && \
    ln -sf "$LUA_LS_DIR/bin/lua-language-server" /usr/local/bin/lua-language-server && \
    ok "lua-language-server installé → /usr/local/bin/lua-language-server" || \
    warn "lua-language-server : échec du téléchargement."
fi

echo ""
echo "=== Done ! ==="
echo ""
echo "LSP disponibles :"
for cmd in pylsp typescript-language-server bash-language-server yaml-language-server lua-language-server; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${RED}✗${NC} $cmd"
    fi
done
LSPEOF
chmod +x /usr/local/bin/install-lsp-servers

# ============================================================
# 10. PERMISSIONS
# ============================================================
chown -R "$REAL_USER:$REAL_USER" "${REAL_HOME}/.config/nvim"
chown -R "$REAL_USER:$REAL_USER" "${REAL_HOME}/.local/share/nvim" 2>/dev/null || true
chown "$REAL_USER:$REAL_USER" "${REAL_HOME}/.tmux.conf"
chown "$REAL_USER:$REAL_USER" "${REAL_HOME}/.tmux-welcome.sh"
chown "$REAL_USER:$REAL_USER" "$ALIAS_FILE"

# ============================================================
# 11. RESUME
# ============================================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ${GREEN}${BOLD}Installation terminee !${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}LazyVim :${NC} ts_ls + pyright + lua_ls + bashls (ShellCheck) | Treesitter | Harpoon2 | TokyoNight"
echo -e "${GREEN}Tmux    :${NC} Welcome screen | Alt+Fleches | Ctrl+A v/b | Resize Ctrl+Fl."
echo ""
echo -e "${YELLOW}Etapes suivantes :${NC}"
echo "  1. source ~/.bashrc"
echo "  2. nvim                     (LazyVim finit l'install)"
echo "  3. tmux                     (welcome screen auto)"
echo "     Ctrl+A + I               (installer plugins TPM)"
echo "  4. sudo install-lsp-servers (optionnel)"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
