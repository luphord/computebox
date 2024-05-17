#!/bin/bash

set -eux pipefail

# variables
GIT_USER="$USER"
GIT_EMAIL="$GIT_USER@protonmail.com"

START=$(date +%s)

# initial update for base packages
sudo apt-get update

# install base packages required for adding PPAs
sudo apt-get install -y curl dirmngr ca-certificates software-properties-common apt-transport-https -y

# install debian packages
sudo apt-get install -y \
    micro xsel xdotool tmux fzf tldr nnn tree lsd ncdu trash-cli htop btop nvtop ddgr pastebinit qrencode timg neofetch cmatrix \
    git fossil mercurial subversion \
    python3 python3-setuptools python3-pip python3-venv python3-tk python3-pil python3-pil.imagetk python3-doit pipx \
    python3-mypy python3-mypy-extensions black \
    jupyter jupyter-qtconsole python3-jupyterlab-server python3-ipywidgets ipython3 python3-numpy python3-matplotlib-inline python3-matplotlib python3-scipy python3-pandas quantlib-python \
    python3-doc python3-numpydoc \
    sbcl slime chezscheme tcc valac \
    sqlitebrowser meld glade spyder geany pspp \
    virt-manager qemu-kvm qemu-utils qemu-block-extra docker.io docker-compose \
    screenkey impressive redshift dex rofi dmenu \
    firefox keepass2 \
    alacritty kitty

# perform upgrade of packages contained before remastering
sudo apt-get upgrade -y

# add user to docker group
sudo usermod -aG docker $USER

# install nix package manager
which nix || sh <(curl -L https://nixos.org/nix/install) --no-daemon
which nix || echo '. ~/.nix-profile/etc/profile.d/nix.sh' >> ~/.bashrc
which nix || . ~/.nix-profile/etc/profile.d/nix.sh

# install nix packages
nix-env -iA \
  nixpkgs.wezterm \
  nixpkgs.zellij \
  nixpkgs.helix \
  nixpkgs.lazygit \
  nixpkgs.lazydocker \
  nixpkgs.vscodium \
  nixpkgs.ventoy-full \
  nixpkgs.dotnet-sdk_8 \
  nixpkgs.deno

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
sudo chmod +x /usr/share/applications/ipython.desktop

# Create WebApp script
sudo cp create_webapp.py /usr/local/bin

# Prepare wallpaper
cp -r wallpaper ~/Pictures


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
JULIAUP=$(which juliaup || echo ~/.juliaup/bin/juliaup)
JULIA=$(which julia || echo ~/.juliaup/bin/julia)
DEFAULT_JULIA_VERSION=$("$JULIAUP" status | grep '*' | awk '{ print $3 }')
echo "Default julia is $DEFAULT_JULIA_VERSION; should be of the format 1.9.3+0.x64.linux.gnu"


# add Julia REPL to start menu
tee ~/.local/share/applications/julia.desktop > /dev/null <<EOF
[Desktop Entry]
Name=julia
Exec=$JULIA
Comment=Julia REPL
Terminal=true
Icon=julia
Type=Application
EOF
chmod +x ~/.local/share/applications/julia.desktop


# webapp for julia docs
# create_webapp.py file:///home/$USER/.julia/juliaup/julia-$DEFAULT_JULIA_VERSION/share/doc/julia/html/en/index.html -n "Julia Documentation" -i /home/$USER/.julia/juliaup/$DEFAULT_JULIA_VERSION/share/doc/julia/html/en/assets/julia.ico -c Development WebApps

# webapp for python docs
# create_webapp.py file:///usr/share/doc/python3/html/index.html -n "Python Documentation" -i python -c Development WebApps

# VSCodium extensions
# from https://github.com/Microsoft/vscode/issues/56614#issuecomment-754839933
# codium --extensions-dir /usr/share/codium/resources/app/extensions --install-extension julialang.language-julia
codium \
  --install-extension julialang.language-julia \
  --install-extension muhammad-sammy.csharp \
  --install-extension Ionide.Ionide-fsharp 

# git config
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

# alias code=codium
code -v || echo 'alias code=codium' >> ~/.bashrc

# add desktop starters for nix-installed applications
grep ".nix-profile/share" ~/.xsessionrc || echo 'export XDG_DATA_DIRS="$HOME/.nix-profile/share:${XDG_DATA_DIRS}"' >> ~/.xsessionrc
grep ".nix-profile/bin" ~/.xsessionrc || echo 'export PATH="$HOME/.nix-profile/bin:${PATH}"' >> ~/.xsessionrc

# local bin path for pipx
pipx ensurepath

# pipx-installable utilities
python3 -m pipx install rich-cli
python3 -m pipx install euporie
python3 -m pipx install qtile

# Add Qtile session
sudo tee /usr/share/xsessions/qtile.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Qtile
Comment=Qtile Session
Exec=/home/$USER/.local/bin/qtile start
Type=Application
Keywords=wm;tiling
EOF
sudo chmod +x /usr/share/xsessions/qtile.desktop

# Link Qtile configuration folder
ln -sf "$(pwd)/qtile/" ~/.config

# cleanup
sudo apt-get clean && sudo apt-get autoremove -y
nix-collect-garbage -d

# done!
echo "--- SETUP DONE, took $(echo $(date +%s) - $START | bc) sec ---"
