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
	&& echo deb [signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main | sudo tee /etc/apt/sources.list.d/vscodium.list \
    && sudo apt-get update

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
sudo cp create_webapp.py /usr/local/bin

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
sudo tee /etc/skel/README.md > /dev/null <<EOF
"Welcome to a new home!"
EOF

# customize default keyboard layout
sudo tee /etc/default/keyboard > /dev/null <<EOF
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="de"
XKBVARIANT="nodeadkeys"
XKBOPTIONS=""

BACKSPACE="guess"
EOF

# juliaup and julia packages
which juliaup || curl -fsSL https://install.julialang.org | sh -s -- --yes
. ~/.bashrc
DEFAULT_JULIA_VERSION=$(juliaup status | grep '*' | awk '{ print $3 }')
echo "Default julia is $DEFAULT_JULIA_VERSION; should be of the format 1.9.3+0.x64.linux.gnu"

# webapp for julia docs
# create_webapp.py file:///home/$USER/.julia/juliaup/julia-$DEFAULT_JULIA_VERSION/share/doc/julia/html/en/index.html -n "Julia Documentation" -i /home/$USER/.julia/juliaup/$DEFAULT_JULIA_VERSION/share/doc/julia/html/en/assets/julia.ico -c Development WebApps

# webapp for python docs
# create_webapp.py file:///usr/share/doc/python3/html/index.html -n "Python Documentation" -i python -c Development WebApps

# VSCodium extensions
# from https://github.com/Microsoft/vscode/issues/56614#issuecomment-754839933
# codium --extensions-dir /usr/share/codium/resources/app/extensions --install-extension julialang.language-julia
codium --install-extension julialang.language-julia

# git config
git config --global user.name "$(GIT_USER)"
git config --global user.email "$(GIT_EMAIL)"

# alias code=codium
echo 'alias code=codium' >> /home/$USER/.bashrc

# local bin path (required for pipx)
echo 'export PATH=$PATH:$HOME/.local/bin' >> /home/$USER/.bashrc

# pipx-installable utilities
pipx install rich-cli

# cleanup
sudo apt-get clean && sudo apt-get autoremove

# done!
echo "--- SETUP DONE, took $(echo $(date +%s) - $START | bc) sec ---"
