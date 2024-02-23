#!/bin/sh

set -eux pipefail

sudo apt-get install -y \
    arc-theme papirus-icon-theme fonts-powerline cinnamon-desktop-environment \
    gnome-system-monitor gnome-disk-utility gnome-font-viewer gnome-terminal \

# Cinnamon settings
gsettings set org.cinnamon.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.cinnamon.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.cinnamon.desktop.wm.preferences theme "Arc-Dark"

gsettings set org.cinnamon.theme name "Arc-Dark"

# gsettings set org.cinnamon.desktop.background picture-uri "$WALLPAPER"
# gsettings set org.cinnamon.desktop.background picture-options zoom


# Gnome settings
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Arc-Dark"

# gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
# gsettings set org.gnome.desktop.background picture-options zoom
