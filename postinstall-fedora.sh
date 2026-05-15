#!/bin/bash
# postinstall-fedora.sh - Script d'optimisation post-installation Fedora
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_ok()      { echo -e "${GREEN}[OK]${NC}   $1"; }

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Ce script doit être exécuté en tant que root (sudo)${NC}"
    exit 1
fi

print_info "Début de la post-installation Fedora..."

dnf_install_safe() {
    for pkg in "$@"; do
        if dnf list --installed "$pkg" &>/dev/null 2>&1; then
            print_ok "$pkg déjà installé."
        else
            print_info "Installation : $pkg"
            dnf install -y "$pkg" 2>/dev/null \
                && print_ok "$pkg" \
                || print_warning "$pkg : non disponible, ignoré."
        fi
    done
}

# ============================================================
# MISE À JOUR SYSTÈME
# ============================================================
dnf upgrade -y || true
dnf autoremove -y || true

# ============================================================
# RPM FUSION (codecs, extras)
# ============================================================
print_info "Activation de RPM Fusion..."
dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
    2>/dev/null || print_warning "RPM Fusion déjà installé ou indisponible, ignoré."

# ============================================================
# PAQUETS PRINCIPAUX (un par un pour éviter l'échec global dnf5)
# ============================================================
print_info "Installation des paquets..."
dnf_install_safe \
    curl wget git make gcc gcc-c++ kernel-devel \
    openssl-devel ca-certificates gnupg2 unzip zip \
    gzip tar vim neovim htop ncdu tree tmux screen \
    net-tools nmap ufw fail2ban openssh-server rsync jq fzf \
    ripgrep fd-find bat eza duf p7zip strace ltrace \
    lsof iotop nethogs iftop sqlite python3 python3-pip python3-virtualenv \
    autoconf ncurses-devel elfutils-libelf-devel \
    flex bison bc cpio kmod gawk dkms \
    libudev-devel pciutils-devel llvm \
    zstd lzop sassc xclip xsel nodejs npm \
    unrar fastfetch

print_info "Installation de micro..."
if command -v micro &>/dev/null; then
    print_ok "micro déjà installé."
else
    curl -fsSL https://getmic.ro | bash && mv micro /usr/local/bin/micro \
        && print_ok "micro installé." \
        || print_warning "micro : échec de l'installation."
fi

# ============================================================
# NERD FONT
# ============================================================
print_info "Installation de HackNerdFont..."
mkdir -p /usr/local/share/fonts
curl -fsSL https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFontMono-Regular.ttf \
    -o /usr/local/share/fonts/HackNerdFontMono-Regular.ttf && fc-cache -fv \
    || print_warning "HackNerdFont : échec du téléchargement."

# ============================================================
# WEZTERM via COPR
# ============================================================
print_info "Installation de WezTerm..."
if command -v wezterm &>/dev/null; then
    print_ok "WezTerm déjà installé."
else
    dnf copr enable -y wezfurlong/wezterm-nightly 2>/dev/null || \
        dnf copr enable -y wez/wezterm 2>/dev/null || true
    dnf install -y wezterm 2>/dev/null || \
        (print_warning "COPR WezTerm échoué, tentative flatpak..." && \
         flatpak install -y flathub org.wezfurlong.wezterm 2>/dev/null || \
         print_warning "WezTerm non installé.")
fi

WEZTERM_CONFIG_URL="https://raw.githubusercontent.com/ps81frt/dotfile-fedora44/refs/heads/main/wezterm.lua"
curl -fsSL "$WEZTERM_CONFIG_URL" -o /tmp/wezterm.lua 2>/dev/null && {
    mkdir -p /root/.config/wezterm
    cp /tmp/wezterm.lua /root/.config/wezterm/wezterm.lua

    while IFS=: read -r username _ uid _ _ homedir _; do
        if [[ $uid -ge 1000 && $uid -lt 65534 && -d "$homedir" ]]; then
            mkdir -p "$homedir/.config/wezterm"
            cp /tmp/wezterm.lua "$homedir/.config/wezterm/wezterm.lua"
            chown -R "$username":"$username" "$homedir/.config/wezterm"
        fi
    done </etc/passwd
    rm -f /tmp/wezterm.lua
} || print_warning "wezterm.lua : téléchargement échoué."

# ============================================================
# VIM CONFIG
# ============================================================
cat >/root/.vimrc <<'EOF'
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set mouse=a
set encoding=utf-8
syntax on
set background=dark
colorscheme desert
set cursorline
set showmatch
set hlsearch
set incsearch
set ignorecase
set smartcase

nnoremap <space> :
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>
nnoremap <C-q> :q!<CR>
EOF

if [ -n "$SUDO_USER" ]; then
    cp /root/.vimrc /home/"$SUDO_USER"/.vimrc
    chown "$SUDO_USER":"$SUDO_USER" /home/"$SUDO_USER"/.vimrc
fi

# ============================================================
# HTOP CONFIG
# ============================================================
mkdir -p /root/.config/htop
cat >/root/.config/htop/htoprc <<'EOF'
fields=0 48 17 18 38 39 40 2 46 47 49 1
sort_key=46
sort_direction=1
tree_view=0
hide_threads=0
hide_kernel_threads=0
hide_userland_threads=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
highlight_changes=1
highlight_changes_delay_secs=5
show_cpu_usage=1
show_cpu_frequency=0
show_cpu_temperature=0
color_scheme=0
enable_mouse=0
delay=15
left_meters=LeftCPUs2 Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs2 Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
EOF

# ============================================================
# FIREWALL (firewalld natif Fedora)
# ============================================================
print_info "Configuration du firewall (firewalld)..."
systemctl enable --now firewalld 2>/dev/null || true
firewall-cmd --permanent --add-service=ssh   2>/dev/null || true
firewall-cmd --permanent --add-service=http  2>/dev/null || true
firewall-cmd --permanent --add-service=https 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

# ============================================================
# FAIL2BAN
# ============================================================
print_info "Configuration de fail2ban..."
systemctl enable fail2ban 2>/dev/null || true
systemctl start  fail2ban 2>/dev/null || true

# ============================================================
# OPTIMISATIONS SYSTÈME
# ============================================================
print_info "Optimisations système..."

cat >>/etc/security/limits.conf <<'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

cat >>/etc/sysctl.conf <<'EOF'
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p 2>/dev/null || true

# ============================================================
# ALIAS BASH
# ============================================================
print_info "Création des alias..."
BASHRC_TARGET="/home/$SUDO_USER/.bashrc"
[ -z "$SUDO_USER" ] && BASHRC_TARGET="$HOME/.bashrc"

cat >>"$BASHRC_TARGET" <<'EOF'

# === Alias Fedora post-install ===
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo dnf upgrade -y'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='dnf search'
alias ports='ss -tulpn'
alias meminfo='free -m -h'
alias disks='df -h'
alias myip='curl ifconfig.me'
alias weather='curl wttr.in'
alias cheat='curl cheat.sh'
alias hist='history | grep'
alias mkdir='mkdir -pv'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias tree='tree -C'
alias htop='htop -C'
alias editp='gnome-text-editor'
alias fetch='fastfetch'
alias cls='clear'
alias v='nvim'

histdel() {
    history -c; history -w
    rm -f ~/.bash_history
    source ~/.bashrc
}

alias logout='gnome-session-quit --logout --no-prompt'

if command -v bat &>/dev/null; then alias cat='bat'; fi

if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -la --icons'
    alias tree='eza --tree --icons'
fi

if command -v duf &>/dev/null; then alias df='duf'; fi

mkcd() { mkdir -p "$1" && cd "$1"; }

ex() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar e "$1" ;;
            *.gz)      gunzip "$1"  ;;
            *.tar)     tar xf "$1"  ;;
            *.zip)     unzip "$1"   ;;
            *.7z)      7z x "$1"    ;;
            *) echo "'$1' ne peut pas être extrait" ;;
        esac
    else
        echo "'$1' n'est pas un fichier valide"
    fi
}
EOF

# ============================================================
# NETTOYAGE
# ============================================================
print_info "Nettoyage..."
dnf clean all 2>/dev/null || true
dnf autoremove -y 2>/dev/null || true

print_info "Post-installation Fedora terminée avec succès !"
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Recommandations :${NC}"
echo -e "${YELLOW}• Redémarrez la session pour activer les alias${NC}"
echo -e "${YELLOW}• Firewall firewalld déjà actif${NC}"
echo -e "${YELLOW}• Lancez nvim_tmux_setup-fedora.sh pour LazyVim + Tmux${NC}"
echo -e "${GREEN}================================${NC}"
