#!/bin/sh

set -eux pipefail

# variables
GIT_USER="$USER"
GIT_EMAIL="$GIT_USER@protonmail.com"

START=$(date +%s)

# initial update for base packages
sudo apt-get update

# install base packages required for adding PPAs
sudo apt-get install -y curl dirmngr ca-certificates software-properties-common apt-transport-https -y

# VSCodium PPA
apt-get install codium -s >> /dev/null \
	|| curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscodium.gpg > /dev/null \
	&& echo deb [signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main | sudo tee /etc/apt/sources.list.d/vscodium.list

# actual update including PPAs
sudo apt-get update

# install packages
sudo apt-get install -y \
    micro xsel xdotool tmux fzf tree htop btop nvtop neofetch \
    git fossil mercurial subversion \
    python3 python3-setuptools python3-pip python3-venv python3-tk python3-pil python3-pil.imagetk python3-doit pipx \
    python3-mypy python3-mypy-extensions black \
    jupyter jupyter-qtconsole python3-jupyterlab-server python3-ipywidgets ipython3 python3-numpy python3-matplotlib-inline python3-matplotlib python3-scipy python3-pandas quantlib-python \
    python3-doc python3-numpydoc \
    sbcl slime chezscheme tcc valac \
    sqlitebrowser meld glade codium spyder geany \
    virt-manager qemu-kvm qemu-utils qemu-block-extra docker.io docker-compose \
    screenkey redshift \
    firefox keepass2 \
    arc-theme papirus-icon-theme

# perform upgrade of packages contained before remastering
sudo apt-get upgrade -y

# add "Open in VSCodium" button to nemo file manager
sudo tee /usr/share/nemo/actions/vscodium.nemo_action > /dev/null <<EOF
[Nemo Action]
Name=Open in VSCodium
Comment=Open the current directory in VSCodium

Exec=codium %P
Icon-Name=vscodium
Selection=none
Extensions=any
EOF

# add "Open in IPython" button to nemo file manager
sudo tee /usr/share/nemo/actions/ipython.nemo_action > /dev/null <<EOF
[Nemo Action]
Name=Open in IPython
Comment=Open the current directory in IPython

Exec=gnome-terminal --working-directory %P -- ipython3
Icon-Name=ipython
Selection=none
Extensions=any
EOF

# add IPython to start menu
sudo tee /usr/share/applications/ipython.desktop > /dev/null <<EOF
[Desktop Entry]
Name=ipython
Exec=ipython3
Comment=Enhanced interactive Python 3 shell
Terminal=true
Icon=ipython
Type=Application
EOF

# add Julia REPL to start menu
sudo tee /usr/share/applications/julia.desktop > /dev/null <<EOF
[Desktop Entry]
Name=julia
Exec=julia
Comment=Julia REPL
Terminal=true
Icon=julia
Type=Application
EOF

# Create WebApp script
mv create_webapp.py /usr/local/bin

# Prepare wallpaper
mkdir -p ~/Pictures/wallpaper
cp computebox-wallpaper.jpg ~/Pictures/wallpaper
WALLPAPER="file:///home/$USER/Pictures/wallpaper/computebox-wallpaper.jpg"

# Cinnamon settings
gsettings set org.cinnamon.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.cinnamon.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.cinnamon.desktop.wm.preferences theme "Arc-Dark"

gsettings set org.cinnamon.theme name "Arc-Dark"

gsettings set org.cinnamon.desktop.background picture-uri "$WALLPAPER"
gsettings set org.cinnamon.desktop.background picture-options zoom


# Gnome settings
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Arc-Dark"

gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
gsettings set org.gnome.desktop.background picture-options zoom

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
JULIAUP=/home/$USER/.juliaup/bin/juliaup
DEFAULT_JULIA_VERSION=`sudo -u luphord $JULIAUP status | grep '*' | awk '{ print $3 }'`
echo "Default julia is $DEFAULT_JULIA_VERSION; should be of the format 1.9.3+0.x64.linux.gnu"

# webapp for julia docs
sudo -u $USER create_webapp.py file:///home/$USER/.julia/juliaup/julia-$DEFAULT_JULIA_VERSION/share/doc/julia/html/en/index.html -n "Julia Documentation" -i /home/$USER/.julia/juliaup/$DEFAULT_JULIA_VERSION/share/doc/julia/html/en/assets/julia.ico -c Development WebApps

# webapp for python docs
sudo -u $USER create_webapp.py file:///usr/share/doc/python3/html/index.html -n "Python Documentation" -i python -c Development WebApps

# VSCodium extensions
# from https://github.com/Microsoft/vscode/issues/56614#issuecomment-754839933
# codium --extensions-dir /usr/share/codium/resources/app/extensions --install-extension julialang.language-julia
sudo -u $USER codium --install-extension julialang.language-julia

# git config
sudo -u $USER git config --global user.name "$(GIT_USER)"
sudo -u $USER git config --global user.email "$(GIT_EMAIL)"

# alias code=codium
sudo -u $USER echo 'alias code=codium' >> /home/$USER/.bashrc

# local bin path (required for pipx)
sudo -u $USER echo 'export PATH=$PATH:$HOME/.local/bin' >> /home/$USER/.bashrc

# pipx-installable utilities
sudo -u $USER pipx install rich-cli

# cleanup
apt-get clean
rm -r /tmp/*
rm -r /root/*
rm -r /var/cache/*

# done!
echo "--- SETUP DONE, took $(echo $(date +%s) - $START | bc) sec ---"
