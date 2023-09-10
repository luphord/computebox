#!/bin/sh

# variables
USER=luphord

set -e

START=$(date +%s)

# initial update for base packages
apt-get update
# install base packages required for adding PPAs
apt-get install -y curl dirmngr ca-certificates software-properties-common apt-transport-https -y
# VSCodium PPA
curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscodium.gpg > /dev/null
echo deb [signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main | sudo tee /etc/apt/sources.list.d/vscodium.list
# cubic PPA
apt-add-repository -y ppa:cubic-wizard/release
# actual update including PPAs
apt-get update
# remove packages deemed unnecessary for this use case
apt-get autoremove -y --purge libreoffice-* drawing hexchat hypnotix rhythmbox thunderbird
# install packages
apt-get install -y \
    micro xsel xdotool git fossil tmux tree htop btop nvtop neofetch \
    python3 python3-setuptools python3-pip python3-venv python3-tk python3-pil python3-pil.imagetk python3-doit pipx \
    sqlitebrowser cubic codium docker.io docker-compose \
    rpi-imager \
    virt-manager qemu-kvm qemu-utils qemu-block-extra \
    screenkey \
    firefox keepass2 \
    arc-theme papirus-icon-theme
# perform upgrade of packages contained before remastering
apt-get upgrade -y

# Create WebApp script
mv create_webapp.py /usr/local/bin

# Cinnamon settings
# gsettings set org.cinnamon.desktop.interface icon-theme "Papirus"
# gsettings set org.cinnamon.desktop.interface gtk-theme "Arc-Dark"
# gsettings set org.cinnamon.theme name "Arc-Dark"
cp computebox-wallpaper.jpg /usr/share/backgrounds/
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
picture-uri='file:///usr/share/backgrounds/computebox-wallpaper.jpg'
picture-options='zoom'
EOF
glib-compile-schemas .
# Prepare user home
echo "Welcome to remastered home!" > /etc/skel/README.md

# customize default keyboard layout
cat << EOF > /etc/default/keyboard
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT="nodeadkeys"
XKBOPTIONS=""

BACKSPACE="guess"
EOF

# customize user $USER
useradd -s /bin/bash -m $USER
usermod -a -G adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,lpadmin,docker $USER
# from https://www.makeuseof.com/enable-disable-auto-login-on-linux-mint/
cat << EOF > /etc/lightdm/lightdm.conf
[Seat:*]
autologin-guest=false
autologin-user=$USER
autologin-user-timeout=0
EOF
cd /home/$USER
# juliaup and julia packages
sudo -u $USER curl -fsSL https://install.julialang.org | sudo -u $USER sh -s -- --yes
# webapp for julia docs
sudo -u $USER create_webapp.py /home/$USER/.julia/juliaup/julia-1.9.2+0.x64.linux.gnu/share/doc/julia/html/en/index.html -n "Julia Documentation" -i /home/$USER/.julia/juliaup/julia-1.9.2+0.x64.linux.gnu/share/doc/julia/html/en/assets/julia.ico -c Development WebApps
# VSCodium extensions
# from https://github.com/Microsoft/vscode/issues/56614#issuecomment-754839933
# codium --extensions-dir /usr/share/codium/resources/app/extensions --install-extension julialang.language-julia
sudo -u $USER codium --install-extension julialang.language-julia

# git config
sudo -u $USER git config --global user.name "$USER"
sudo -u $USER git config --global user.email "$USER@protonmail.com"

# alias code=codium
sudo -u $USER echo 'alias code=codium' >> /home/$USER/.bashrc

# change user password
echo "--- CHANGE PASSWORD FOR USER $USER ---"
passwd $USER

# cleanup
apt-get clean
rm -r /tmp/*
rm -r /root/*
rm -r /var/cache/*

# done!
echo "--- DONE REMASTERING, took $(echo $(date +%s) - $START | bc) sec ---"
