#!/bin/bash

########################################
# GNOME POST INSTALL - Fedora
########################################

# Vérification root
if [[ $(id -u) -eq 0 ]]; then
    echo -e "\033[31mATTENTION\033[0m"
    echo "Vous lancez ce script en root."
    echo "La session GNOME root sera modifiée."
    echo "Poursuite dans 10 secondes..."
    sleep 10
fi

########################################
# CONFIGURATION GÉNÉRALE
########################################

echo "Configuration générale de GNOME"

# Boutons fenêtres
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Volume >100%
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Popup détachées
gsettings set org.gnome.mutter attach-modal-dialogs false

# Calendrier
gsettings set org.gnome.desktop.calendar show-weekdate true

# Horloge
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format '24h'

# Pointer locate
gsettings set org.gnome.desktop.interface locate-pointer true

# Touchpad
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas'
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Sons système
gsettings set org.gnome.desktop.wm.preferences audible-bell false

# Hot corner OFF
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Timeout app freeze
gsettings set org.gnome.mutter check-alive-timeout 60000

# Night light
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true

# Nettoyage auto
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy old-files-age 30

########################################
# CONFIDENTIALITÉ
########################################

echo "Configuration confidentialité"

gsettings set org.gnome.desktop.privacy report-technical-problems false
gsettings set org.gnome.desktop.privacy send-software-usage-stats false
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy recent-files-max-age -1

########################################
# APPARENCE
########################################

echo "Personnalisation GNOME"

# Dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Theme GTK — Fedora utilise Adwaita par défaut (Yaru est Ubuntu-only)
# On essaie Adwaita-dark, sinon on garde le défaut
if gsettings list-schemas | grep -q "org.gnome.desktop.interface"; then
    AVAILABLE_THEMES=$(ls /usr/share/themes/ 2>/dev/null)
    if echo "$AVAILABLE_THEMES" | grep -q "adw-gtk3-dark"; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    else
        echo "Thème adw-gtk3-dark absent. Pour l'installer : sudo dnf install adw-gtk3"
        echo "Thème GTK laissé par défaut (Adwaita)."
    fi
fi

# Icônes — Fedora n'a pas Yaru, Papirus est une bonne alternative
if ls /usr/share/icons/ 2>/dev/null | grep -q "Papirus"; then
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
else
    echo "Papirus absent. Pour l'installer : sudo dnf install papirus-icon-theme"
fi

# Curseur
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'

# Animations
gsettings set org.gnome.desktop.interface enable-animations true

########################################
# NAUTILUS
########################################

echo "Configuration Nautilus"

# Vue liste
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

# Tree view
gsettings set org.gnome.nautilus.list-view use-tree-view true

# Zoom
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'

# DnD
gsettings set org.gnome.nautilus.preferences open-folder-on-dnd-hover false

# Double clic
gsettings set org.gnome.nautilus.preferences click-policy 'double'

# Tri dossiers
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true

########################################
# GNOME SOFTWARE
########################################
echo "Configuration GNOME Software"

if gsettings list-schemas | grep -q "org.gnome.software"; then
    gsettings set org.gnome.software download-updates false
    gsettings set org.gnome.software show-only-free-apps false
else
    echo "GNOME Software absent, ignoré."
fi

########################################
# TEXT EDITOR
########################################

echo "Configuration Text Editor"

gsettings set org.gnome.TextEditor highlight-current-line false
gsettings set org.gnome.TextEditor restore-session false
gsettings set org.gnome.TextEditor show-line-numbers true

########################################
# GNOME WEB
########################################

echo "Configuration GNOME Web"

if gsettings list-schemas | grep -q "org.gnome.Epiphany"; then
    gsettings set org.gnome.Epiphany ask-for-default false
    gsettings set org.gnome.Epiphany homepage-url 'about:blank'
    gsettings set org.gnome.Epiphany start-in-incognito-mode true
else
    echo "GNOME Web absent, ignoré."
fi

########################################
# TERMINAL (Ptyxis ou GNOME Terminal)
########################################

echo "Configuration terminal"

# Ptyxis (disponible sur Fedora 40+)
if gsettings list-schemas | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name 'Monospace 13'
    gsettings set org.gnome.Ptyxis restore-session false
    echo "Ptyxis configuré."
else
    echo "Ptyxis absent, ignoré."
fi

########################################
# FONTS
########################################

echo "Configuration polices"

# Fedora n'a pas Ubuntu fonts par défaut — on utilise Cantarell (défaut Fedora)
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 13'

# Si HackNerdFont installé (via postinstall-fedora.sh), on l'utilise
if fc-list | grep -q "HackNerdFontMono"; then
    gsettings set org.gnome.desktop.interface monospace-font-name 'HackNerdFontMono 13'
    echo "HackNerdFontMono détecté et utilisé."
fi

########################################
# DASH TO DOCK
########################################

echo "Configuration Dock"

read -r -p "Installer Dash to Dock depuis GitHub ? (o/N): " choix

if [[ $choix =~ ^[oO]$ ]]; then
    if ! command -v sassc &>/dev/null; then
        echo "sassc manquant, installez-le : sudo dnf install sassc. Dash to Dock ignoré."
    else
        git clone https://github.com/micheleg/dash-to-dock.git /tmp/dash-to-dock
        cd /tmp/dash-to-dock || {
            echo "Impossible d'accéder au dossier cloné"
            cd /
        }

        DEST="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
        mkdir -p "$DEST"

        if make DESTDIR="$HOME/.local"; then
            glib-compile-schemas "$DEST/schemas/"
            echo "Dash to Dock compilé avec succès."
        else
            echo "Erreur de compilation, Dash to Dock ignoré."
        fi

        cd / || true
        rm -rf /tmp/dash-to-dock
    fi
fi

if gnome-extensions list | grep -q "dash-to-dock@micxgx.gmail.com"; then
    gnome-extensions enable dash-to-dock@micxgx.gmail.com

    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
    gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'MAXIMIZED_WINDOWS'
    gsettings set org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen true
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 42
    gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
    gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.80
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
    gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
    gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
    gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
else
    echo "Dash to Dock absent. Sur Fedora, le dock GNOME natif sera utilisé."
    # Pas d'ubuntu-dock sur Fedora, on configure via gsettings généraux
fi

########################################
# APPINDICATOR
########################################
echo "Activation AppIndicator"

if gnome-extensions list | grep -q "appindicatorsupport@rgcjonas.gmail.com"; then
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
else
    echo "AppIndicator absent."
    echo "Pour l'installer : sudo dnf install gnome-shell-extension-appindicator"
fi

########################################
# RACCOURCI TERMINAL (WezTerm)
########################################
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'WezTerm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wezterm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>t'

########################################
# EXTENSIONS BONUS
########################################

echo "Extensions recommandées (installables via GNOME Extensions ou dnf)"
echo " - Blur My Shell       : sudo dnf install gnome-shell-extension-blur-my-shell"
echo " - Just Perfection     : via extensions.gnome.org"
echo " - Extension Manager   : sudo flatpak install com.mattjakeman.ExtensionManager"
echo " - AppIndicator        : sudo dnf install gnome-shell-extension-appindicator"
echo " - adw-gtk3 (thème)    : sudo dnf install adw-gtk3"
echo " - Papirus (icônes)    : sudo dnf install papirus-icon-theme"

########################################
# FINAL
########################################

echo ""
echo "===================================="
echo "Personnalisation terminée."
echo "Redémarrez votre session GNOME."
echo "===================================="
