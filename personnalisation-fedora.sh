#!/bin/bash

########################################
# GNOME POST INSTALL - Fedora
########################################

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

gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
gsettings set org.gnome.mutter attach-modal-dialogs false
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface locate-pointer true
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas'
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.wm.preferences audible-bell false
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.mutter check-alive-timeout 60000
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
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

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

if ls /usr/share/themes/ 2>/dev/null | grep -q "adw-gtk3-dark"; then
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
else
    echo "adw-gtk3-dark absent. Pour l'installer : sudo dnf install adw-gtk3"
fi

if ls /usr/share/icons/ 2>/dev/null | grep -q "Papirus"; then
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
else
    echo "Papirus absent. Pour l'installer : sudo dnf install papirus-icon-theme"
fi

gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface enable-animations true

########################################
# NAUTILUS
########################################

echo "Configuration Nautilus"

gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view use-tree-view true
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'
gsettings set org.gnome.nautilus.preferences open-folder-on-dnd-hover false
gsettings set org.gnome.nautilus.preferences click-policy 'double'
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
# PTYXIS
########################################

echo "Configuration Ptyxis"

if gsettings list-schemas | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name 'Monospace 13'
    gsettings set org.gnome.Ptyxis restore-session false
else
    echo "Ptyxis absent, ignoré."
fi

########################################
# FONTS
########################################

echo "Configuration polices"

gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 13'

if fc-list | grep -q "HackNerdFontMono"; then
    gsettings set org.gnome.desktop.interface monospace-font-name 'HackNerdFontMono 13'
fi

########################################
# DASH TO DOCK
########################################

echo "Configuration Dock"

DEST="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"

read -r -p "Installer Dash to Dock depuis GitHub ? (o/N): " choix

if [[ $choix =~ ^[oO]$ ]]; then
    if ! command -v sassc &>/dev/null; then
        echo "sassc manquant, lancez postinstall-fedora.sh d'abord. Dash to Dock ignoré."
    else
        rm -rf /tmp/dash-to-dock /tmp/dtd-build
        git clone https://github.com/micheleg/dash-to-dock.git /tmp/dash-to-dock
        cd /tmp/dash-to-dock || exit 1

        make DESTDIR=/tmp/dtd-build install 2>&1 | tail -3

        BUILT=$(find /tmp/dtd-build -type d -name "dash-to-dock@micxgx.gmail.com" 2>/dev/null | head -1)

        if [ -n "$BUILT" ]; then
            mkdir -p "$DEST"
            cp -r "$BUILT/." "$DEST/"
            if [ -d "$DEST/schemas" ]; then
                glib-compile-schemas "$DEST/schemas/"
                echo "Dash to Dock compilé avec succès."
            fi
        else
            echo "Erreur de compilation, Dash to Dock ignoré."
        fi

        cd / || true
        rm -rf /tmp/dash-to-dock /tmp/dtd-build
    fi
fi

if [ -d "$DEST" ] && [ -f "$DEST/metadata.json" ]; then
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell \
        --method org.gnome.Shell.Extensions.EnableExtension \
        "dash-to-dock@micxgx.gmail.com" 2>/dev/null && \
        echo "Dash to Dock activé." || \
        echo "Déconnectez/reconnectez puis : gnome-extensions enable dash-to-dock@micxgx.gmail.com"

    if gsettings list-schemas | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
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
    fi
else
    echo "Dash to Dock non installé. Dock GNOME natif utilisé."
fi

########################################
# APPINDICATOR
########################################

echo "Activation AppIndicator"

if gnome-extensions list 2>/dev/null | grep -q "appindicatorsupport@rgcjonas.gmail.com"; then
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
else
    echo "AppIndicator absent. Pour l'installer : sudo dnf install gnome-shell-extension-appindicator"
fi

########################################
# TERMINAL
########################################

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'WezTerm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wezterm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>t'

########################################
# EXTENSIONS BONUS
########################################

echo "Extensions recommandées"

echo "Installer si absent :"
echo " - Blur My Shell      : sudo dnf install gnome-shell-extension-blur-my-shell"
echo " - Just Perfection    : https://extensions.gnome.org/extension/3843/just-perfection/"
echo " - Extension Manager  : flatpak install com.mattjakeman.ExtensionManager"
echo " - adw-gtk3 (thème)   : sudo dnf install adw-gtk3"
echo " - Papirus (icônes)   : sudo dnf install papirus-icon-theme"

########################################
# FINAL
########################################

echo ""
echo "===================================="
echo "Personnalisation terminée."
echo "Redémarrez votre session GNOME."
echo "===================================="
