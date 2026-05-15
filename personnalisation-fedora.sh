#!/bin/bash

########################################
#         GNOME POST INSTALL           #
#               Fedora                 #
########################################

if [[ $(id -u) -eq 0 ]]; then
    echo -e "\033[31mATTENTION\033[0m"
    echo "Vous lancez ce script en root."
    echo "La session GNOME root sera modifiée."
    echo "Poursuite dans 10 secondes..."
    sleep 10
fi

########################################
#          CONFIGURATION GÉNÉRALE      #
########################################

echo "Configuration générale de GNOME"

echo " - Boutons de fenêtre"
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
echo " - Suramplification"
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
echo " - Détacher les popups des fenêtres"
gsettings set org.gnome.mutter attach-modal-dialogs false
echo " - Affichage du calendrier dans le panneau supérieur"
gsettings set org.gnome.desktop.calendar show-weekdate true
echo " - Date et heure (format 24h)"
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format '24h'
echo " - Localisation du pointeur via CTRL"
gsettings set org.gnome.desktop.interface locate-pointer true
echo " - Paramétrage Touch Pad"
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas'
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
echo " - Désactivation des sons système"
gsettings set org.gnome.desktop.wm.preferences audible-bell false
echo " - Désactivation des hot corners"
gsettings set org.gnome.desktop.interface enable-hot-corners false
echo " - Timeout des applications en attente de réponse à 60s"
gsettings set org.gnome.mutter check-alive-timeout 60000
echo " - Activation du mode nuit"
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
echo " - Épuration des fichiers temporaires et de la corbeille de plus de 30 jours"
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy old-files-age 30

########################################
#             CONFIDENTIALITÉ          #
########################################

echo "Configuration confidentialité"

echo " - Désactivation de l'envoi des rapports"
gsettings set org.gnome.desktop.privacy report-technical-problems false
echo " - Désactivation des statistiques des logiciels"
gsettings set org.gnome.desktop.privacy send-software-usage-stats false
echo " - Désactivation de l'historique des fichiers récents"
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy recent-files-max-age -1

########################################
#               APPARENCE              #
########################################

echo "Personnalisation de GNOME"

echo " - Application du thème sombre"
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
#               NAUTILUS               #
########################################

echo "Configuration Nautilus"

echo " - Vue liste et activation du mode tree"
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view use-tree-view true
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'
echo " - Désactivation de l'ouverture du dossier lors d'un glisser-déposer"
gsettings set org.gnome.nautilus.preferences open-folder-on-dnd-hover false
echo " - Activation du double clic"
gsettings set org.gnome.nautilus.preferences click-policy 'double'
echo " - Dossiers en premier"
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true

########################################
#            GNOME SOFTWARE            #
########################################

echo "Configuration de GNOME Logiciels"

if gsettings list-schemas | grep -q "org.gnome.software"; then
    echo " - Désactivation du téléchargement automatique des mises à jour"
    gsettings set org.gnome.software download-updates false
    echo " - Activation de l'affichage des logiciels propriétaires"
    gsettings set org.gnome.software show-only-free-apps false
else
    echo "GNOME Software absent, ignoré."
fi

########################################
#            TEXT EDITOR               #
########################################

echo "Configuration de GNOME Text Editor"

gsettings set org.gnome.TextEditor highlight-current-line false
gsettings set org.gnome.TextEditor restore-session false
gsettings set org.gnome.TextEditor show-line-numbers true

########################################
#              GNOME WEB               #
########################################

echo "Configuration de GNOME Web"

if gsettings list-schemas | grep -q "org.gnome.Epiphany"; then
    gsettings set org.gnome.Epiphany ask-for-default false
    gsettings set org.gnome.Epiphany homepage-url 'about:blank'
    gsettings set org.gnome.Epiphany start-in-incognito-mode true
else
    echo "GNOME Web absent, ignoré."
fi

########################################
#               PTYXIS                 #
########################################

echo "Configuration de Ptyxis"

if gsettings list-schemas | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name 'Monospace 13'
    gsettings set org.gnome.Ptyxis restore-session false
else
    echo "Ptyxis absent, ignoré."
fi

########################################
#                POLICES               #
########################################

echo "Configuration des polices"

gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 13'

if fc-list | grep -q "HackNerdFontMono"; then
    gsettings set org.gnome.desktop.interface monospace-font-name 'HackNerdFontMono 13'
fi

echo " - Application des fonts Red Hat (si installées)"

if rpm -q redhat-mono-fonts &>/dev/null; then
    gsettings set org.gnome.Ptyxis font-name 'Red Hat Mono Regular 14'
fi

if rpm -q redhat-text-fonts &>/dev/null; then
    gsettings set org.gnome.desktop.interface font-name 'Red Hat Text Regular 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Red Hat Mono Regular 13'
fi

########################################
#            DASH TO DOCK              #
########################################

echo "Configuration du Dock"

DEST="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"

read -r -p "Installer Dash to Dock depuis GitHub ? (o/N): " choix

if [[ $choix =~ ^[oO]$ ]]; then
    if ! command -v sassc &>/dev/null; then
        echo "sassc manquant. Dash to Dock ignoré."
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
        "dash-to-dock@micxgx.gmail.com" 2>/dev/null &&
        echo "Dash to Dock activé." ||
        echo "Déconnectez/reconnectez puis : gnome-extensions enable dash-to-dock@micxgx.gmail.com"

    if gsettings list-schemas | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
        echo " - Placement en bas, masquage intelligent"
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
        echo " - Correction du bug de la double lettre"
        gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
        gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
        gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
    fi
else
    echo "Dash to Dock non installé. Dock GNOME natif utilisé."
fi

########################################
#            APPINDICATOR              #
########################################

echo "Activation de AppIndicator"

if gnome-extensions list 2>/dev/null | grep -q "appindicatorsupport@rgcjonas.gmail.com"; then
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
else
    echo "AppIndicator absent. Pour l'installer : sudo dnf install gnome-shell-extension-appindicator"
fi

########################################
#         RACCOURCI TERMINAL        #!/bin/bash

########################################
#         GNOME POST INSTALL           #
#               Fedora                 #
########################################

if [[ $(id -u) -eq 0 ]]; then
    echo -e "\033[31mATTENTION\033[0m"
    echo "Vous lancez ce script en root."
    echo "La session GNOME root sera modifiée."
    echo "Poursuite dans 10 secondes..."
    sleep 10
fi

########################################
#          CONFIGURATION GÉNÉRALE      #
########################################

echo "Configuration générale de GNOME"

echo " - Boutons de fenêtre"
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
echo " - Suramplification"
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
echo " - Détacher les popups des fenêtres"
gsettings set org.gnome.mutter attach-modal-dialogs false
echo " - Affichage du calendrier dans le panneau supérieur"
gsettings set org.gnome.desktop.calendar show-weekdate true
echo " - Date et heure (format 24h)"
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format '24h'
echo " - Localisation du pointeur via CTRL"
gsettings set org.gnome.desktop.interface locate-pointer true
echo " - Paramétrage Touch Pad"
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas'
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
echo " - Désactivation des sons système"
gsettings set org.gnome.desktop.wm.preferences audible-bell false
echo " - Désactivation des hot corners"
gsettings set org.gnome.desktop.interface enable-hot-corners false
echo " - Timeout des applications en attente de réponse à 60s"
gsettings set org.gnome.mutter check-alive-timeout 60000
echo " - Activation du mode nuit"
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
echo " - Épuration des fichiers temporaires et de la corbeille de plus de 30 jours"
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy old-files-age 30

########################################
#             CONFIDENTIALITÉ          #
########################################

echo "Configuration confidentialité"

echo " - Désactivation de l'envoi des rapports"
gsettings set org.gnome.desktop.privacy report-technical-problems false
echo " - Désactivation des statistiques des logiciels"
gsettings set org.gnome.desktop.privacy send-software-usage-stats false
echo " - Désactivation de l'historique des fichiers récents"
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy recent-files-max-age -1

########################################
#               APPARENCE              #
########################################

echo "Personnalisation de GNOME"

echo " - Application du thème sombre"
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
#               NAUTILUS               #
########################################

echo "Configuration Nautilus"

echo " - Vue liste et activation du mode tree"
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.list-view use-tree-view true
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'
echo " - Désactivation de l'ouverture du dossier lors d'un glisser-déposer"
gsettings set org.gnome.nautilus.preferences open-folder-on-dnd-hover false
echo " - Activation du double clic"
gsettings set org.gnome.nautilus.preferences click-policy 'double'
echo " - Dossiers en premier"
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true

########################################
#            GNOME SOFTWARE            #
########################################

echo "Configuration de GNOME Logiciels"

if gsettings list-schemas | grep -q "org.gnome.software"; then
    echo " - Désactivation du téléchargement automatique des mises à jour"
    gsettings set org.gnome.software download-updates false
    echo " - Activation de l'affichage des logiciels propriétaires"
    gsettings set org.gnome.software show-only-free-apps false
else
    echo "GNOME Software absent, ignoré."
fi

########################################
#            TEXT EDITOR               #
########################################

echo "Configuration de GNOME Text Editor"

gsettings set org.gnome.TextEditor highlight-current-line false
gsettings set org.gnome.TextEditor restore-session false
gsettings set org.gnome.TextEditor show-line-numbers true

########################################
#              GNOME WEB               #
########################################

echo "Configuration de GNOME Web"

if gsettings list-schemas | grep -q "org.gnome.Epiphany"; then
    gsettings set org.gnome.Epiphany ask-for-default false
    gsettings set org.gnome.Epiphany homepage-url 'about:blank'
    gsettings set org.gnome.Epiphany start-in-incognito-mode true
else
    echo "GNOME Web absent, ignoré."
fi

########################################
#               PTYXIS                 #
########################################

echo "Configuration de Ptyxis"

if gsettings list-schemas | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name 'Monospace 13'
    gsettings set org.gnome.Ptyxis restore-session false
else
    echo "Ptyxis absent, ignoré."
fi

########################################
#                POLICES               #
########################################

echo "Configuration des polices"

gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 13'

if fc-list | grep -q "HackNerdFontMono"; then
    gsettings set org.gnome.desktop.interface monospace-font-name 'HackNerdFontMono 13'
fi

echo " - Application des fonts Red Hat (si installées)"

if rpm -q redhat-mono-fonts &>/dev/null; then
    gsettings set org.gnome.Ptyxis font-name 'Red Hat Mono Regular 14'
fi

if rpm -q redhat-text-fonts &>/dev/null; then
    gsettings set org.gnome.desktop.interface font-name 'Red Hat Text Regular 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Red Hat Mono Regular 13'
fi

########################################
#            DASH TO DOCK              #
########################################

echo "Configuration du Dock"

DEST="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"

read -r -p "Installer Dash to Dock depuis GitHub ? (o/N): " choix

if [[ $choix =~ ^[oO]$ ]]; then
    if ! command -v sassc &>/dev/null; then
        echo "sassc manquant. Dash to Dock ignoré."
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
        "dash-to-dock@micxgx.gmail.com" 2>/dev/null &&
        echo "Dash to Dock activé." ||
        echo "Déconnectez/reconnectez puis : gnome-extensions enable dash-to-dock@micxgx.gmail.com"

    if gsettings list-schemas | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
        echo " - Placement en bas, masquage intelligent"
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
        echo " - Correction du bug de la double lettre"
        gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
        gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
        gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
    fi
else
    echo "Dash to Dock non installé. Dock GNOME natif utilisé."
fi

########################################
#            APPINDICATOR              #
########################################

echo "Activation de AppIndicator"

if gnome-extensions list 2>/dev/null | grep -q "appindicatorsupport@rgcjonas.gmail.com"; then
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
else
    echo "AppIndicator absent. Pour l'installer : sudo dnf install gnome-shell-extension-appindicator"
fi

########################################
#         RACCOURCI TERMINAL           #
########################################

echo "Configuration du raccourci terminal (Ctrl+Alt+T -> WezTerm)"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'WezTerm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wezterm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>t'

########################################
#          EXTENSIONS BONUS            #
########################################

echo "Extensions recommandées :"
echo " - Blur My Shell      : sudo dnf install gnome-shell-extension-blur-my-shell"
echo " - Just Perfection    : https://extensions.gnome.org/extension/3843/just-perfection/"
echo " - Extension Manager  : flatpak install com.mattjakeman.ExtensionManager"
echo " - adw-gtk3 (theme)   : sudo dnf install adw-gtk3"
echo " - Papirus (icones)   : sudo dnf install papirus-icon-theme"

########################################
#                 FIN                  #
########################################

echo ""
echo "===================================="
echo "   Personnalisation terminée.       "
echo "   Redémarrez votre session GNOME.  "
echo "====================================" #
########################################

echo "Configuration du raccourci terminal (Ctrl+Alt+T -> WezTerm)"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'WezTerm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wezterm'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>t'
gsettings set org.gnome.desktop.default-applications.terminal exec wezterm

########################################
#          EXTENSIONS BONUS            #
########################################

echo "Extensions recommandées :"
echo " - Blur My Shell      : sudo dnf install gnome-shell-extension-blur-my-shell"
echo " - Just Perfection    : https://extensions.gnome.org/extension/3843/just-perfection/"
echo " - Extension Manager  : flatpak install com.mattjakeman.ExtensionManager"
echo " - adw-gtk3 (theme)   : sudo dnf install adw-gtk3"
echo " - Papirus (icones)   : sudo dnf install papirus-icon-theme"

########################################
#                 FIN                  #
########################################

echo ""
echo "===================================="
echo "   Personnalisation terminée.       "
echo "   Redémarrez votre session GNOME.  "
echo "===================================="
