#!/bin/sh
set -e

START=$(date +%s)

# initial update for base packages
apt-get update
# install base packages required for adding PPAs
apt-get install -y curl dirmngr ca-certificates software-properties-common apt-transport-https -y
# VSCodium PPA
curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscodium.gpg > /dev/null
echo deb [signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main | sudo tee /etc/apt/sources.list.d/vscodium.list
# actual update including PPAs
apt-get update
# remove packages deemed unnecessary for this use case
apt-get autoremove -y --purge libreoffice-* drawing hexchat hypnotix rhythmbox thunderbird
# install packages
apt-get install -y micro git tmux htop btop neofetch sqlitebrowser codium docker.io arc-theme papirus-icon-theme
# perform upgrade of packages contained before remastering
apt-get upgrade -y

# Cinnamon settings
# gsettings set org.cinnamon.desktop.interface icon-theme "Papirus"
# gsettings set org.cinnamon.desktop.interface gtk-theme "Arc-Dark"
# gsettings set org.cinnamon.theme name "Arc-Dark"
cd /usr/share/glib-2.0/schemas
cat << EOF > zz_custom_cinnamon.gschema.override
[x.dm.slick-greeter]
theme-name='Arc-Dark'
icon-theme-name='Papirus-Dark'

[org.gnome.desktop.interface]
icon-theme = 'Papirus-Dark'
gtk-theme = 'Arc-Dark'

[org.cinnamon.desktop.interface]
icon-theme = 'Papirus-Dark'
gtk-theme = 'Arc-Dark'

[org.gnome.desktop.wm.preferences]
theme = 'Arc-Dark'

[org.cinnamon.desktop.wm.preferences]
theme = 'Arc-Dark'

[org.cinnamon.theme]
name = 'Arc-Dark'

[org.cinnamon.desktop.background]
picture-uri='file:///usr/share/backgrounds/linuxmint/ktee_linuxmint.png'
EOF
glib-compile-schemas .
# Prepare user home
echo "Welcome to remastered home!" > /etc/skel/README.md

# customize user luphord
useradd -s /bin/bash -m luphord
usermod -a -G adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,lpadmin,docker luphord
# from https://www.makeuseof.com/enable-disable-auto-login-on-linux-mint/
cat << EOF > /etc/lightdm/lightdm.conf
[Seat:*]
autologin-guest=false
autologin-user=luphord
autologin-user-timeout=0
EOF
cd /home/luphord
# VSCodium extensions
# from https://github.com/Microsoft/vscode/issues/56614#issuecomment-754839933
# codium --extensions-dir /usr/share/codium/resources/app/extensions --install-extension julialang.language-julia
sudo -u luphord codium --install-extension julialang.language-julia

# git config
sudo -u luphord git config --global user.name "luphord"
sudo -u luphord git config --global user.email "luphord@protonmail.com"

# done!
echo "--- DONE REMASTERING, took $(echo $(date +%s) - $START | bc) sec ---"

# change user password
echo "--- CHANGE PASSWORD FOR USER luphord ---"
passwd luphord

