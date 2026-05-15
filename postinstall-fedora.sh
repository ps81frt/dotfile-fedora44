#!/bin/bash
# postinstall-fedora.sh - Script d'optimisation post-installation Fedora

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Ce script doit être exécuté en tant que root (sudo)${NC}"
    exit 1
fi

print_info "Début de la post-installation Fedora..."

# ============================================================
# MISE À JOUR SYSTÈME
# ============================================================
dnf upgrade -y
dnf autoremove -y

# ============================================================
# RPM FUSION (codecs, extras)
# ============================================================
print_info "Activation de RPM Fusion..."
dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" || true

# ============================================================
# PAQUETS PRINCIPAUX
# ============================================================
print_info "Installation des paquets..."
dnf install -y \
    curl wget git make gcc gcc-c++ kernel-devel \
    openssl-devel ca-certificates gnupg2 lsb-release unzip zip \
    gzip tar vim neovim htop ncdu tree tmux screen \
    net-tools nmap ufw fail2ban openssh-server rsync jq fzf \
    ripgrep fd-find bat eza duf p7zip strace ltrace \
    lsof iotop nethogs iftop sqlite python3 python3-pip python3-virtualenv \
    neofetch unrar perl-Fedora-VSPackages autoconf \
    ncurses-devel elfutils-libelf-devel openssl-devel \
    flex bison bc cpio kmod gawk dkms \
    libudev-devel pciutils-devel libiberty-devel llvm \
    zstd lzop sassc xclip xsel nodejs npm

# micro - pas de snap sur Fedora, on prend le binaire officiel
print_info "Installation de micro..."
curl -fsSL https://getmic.ro | bash
mv micro /usr/local/bin/micro || true

# ============================================================
# NERD FONT
# ============================================================
print_info "Installation de HackNerdFont..."
mkdir -p /usr/local/share/fonts
curl -fsSL https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFontMono-Regular.ttf \
    -o /usr/local/share/fonts/HackNerdFontMono-Regular.ttf
fc-cache -fv

# ============================================================
# WEZTERM via COPR
# ============================================================
print_info "Installation de WezTerm..."
dnf copr enable -y wezfurlong/wezterm-nightly || \
    dnf copr enable -y wez/wezterm || true
dnf install -y wezterm || \
    (print_info "COPR échoué, tentative via flatpak..." && \
     flatpak install -y flathub org.wezfurlong.wezterm 2>/dev/null || true)

WEZTERM_CONFIG_URL="https://raw.githubusercontent.com/ps81frt/dotfile-ubuntu/refs/heads/main/wezterm.lua"
curl -fsSL "$WEZTERM_CONFIG_URL" -o /tmp/wezterm.lua

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
tree_view_always_by_pid=0
all_branches_collapsed=0
hide_threads=0
hide_kernel_threads=0
hide_userland_threads=0
shadow_other_users=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
highlight_changes=1
highlight_changes_delay_secs=5
show_cpu_usage=1
show_cpu_frequency=0
show_cpu_temperature=0
tree_view_cpu_usage=0
update_process_names=0
account_guest_in_cpu_meter=1
color_scheme=0
enable_mouse=0
delay=15
left_meters=LeftCPUs2 Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs2 Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
EOF

# ============================================================
# FIREWALL (firewalld sur Fedora, ufw optionnel)
# ============================================================
print_info "Configuration du firewall (firewalld)..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
# ufw aussi si installé
if command -v ufw &>/dev/null; then
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

# ============================================================
# FAIL2BAN
# ============================================================
print_info "Configuration de fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

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

sysctl -p

# ============================================================
# ALIAS BASH
# ============================================================
print_info "Création des alias..."
cat >>"/home/$SUDO_USER/.bashrc" <<'EOF'

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
alias diff='colordiff'
alias tree='tree -C'
alias htop='htop -C'
alias editp='gnome-text-editor'
alias fetch='neofetch'
alias cls='clear'
alias v='nvim'

histdel() {
    history -c
    history -w
    rm -f ~/.bash_history
    source ~/.bashrc
}

alias logout='gnome-session-quit --logout --no-prompt'

if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v eza &> /dev/null; then
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -la --icons'
    alias tree='eza --tree --icons'
fi

if command -v duf &> /dev/null; then
    alias df='duf'
fi

mkcd() {
    mkdir -p "$1" && cd "$1"
}

ex() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2) tar xjf $1 ;;
            *.tar.gz) tar xzf $1 ;;
            *.bz2) bunzip2 $1 ;;
            *.rar) unrar e $1 ;;
            *.gz) gunzip $1 ;;
            *.tar) tar xf $1 ;;
            *.tbz2) tar xjf $1 ;;
            *.tgz) tar xzf $1 ;;
            *.zip) unzip $1 ;;
            *.Z) uncompress $1 ;;
            *.7z) 7z x $1 ;;
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
dnf clean all
dnf autoremove -y

print_info "Installation terminée !"
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Paquets installés :${NC}"
echo -e "${YELLOW}• VIM + Neovim${NC}"
echo -e "${YELLOW}• HTOP${NC}"
echo -e "${YELLOW}• Git, Curl, Wget${NC}"
echo -e "${YELLOW}• Build tools (gcc, make, kernel-devel)${NC}"
echo -e "${YELLOW}• Outils réseau et sécurité${NC}"
echo -e "${YELLOW}• Utilitaires système${NC}"
echo -e "${YELLOW}• Neofetch${NC}"
echo -e "${YELLOW}• WezTerm${NC}"
echo ""
echo -e "${GREEN}Optimisations :${NC}"
echo -e "${YELLOW}• Configuration VIM${NC}"
echo -e "${YELLOW}• Configuration HTOP${NC}"
echo -e "${YELLOW}• Limites système augmentées${NC}"
echo -e "${YELLOW}• Optimisations réseau${NC}"
echo -e "${YELLOW}• Aliases bash pratiques${NC}"
echo ""
echo -e "${GREEN}Recommandations :${NC}"
echo -e "${YELLOW}• Redémarrez votre session pour profiter des alias${NC}"
echo -e "${YELLOW}• Firewall firewalld déjà actif${NC}"
echo -e "${GREEN}================================${NC}"

print_info "Post-installation Fedora terminée avec succès !"
