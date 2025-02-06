#!/bin/bash
# Copyright (c) 2025 Theodor Weinreich
# This script is published under the MIT license.
# Further information can be found in the LICENSE file.

set -e

if [ "$EUID" -ne 0 ] || [ -z "$SUDO_USER" ]; then
    echo "Please run this script with sudo (e.g., 'sudo ./setup.sh')."
    exit 1
fi

USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
if [ -z "$USER_HOME" ]; then
    echo "Could not determine the home directory for user $SUDO_USER."
    exit 1
fi

export HOME="$USER_HOME"

echo "Updating package database and system ..."
pacman -Syu --noconfirm

echo "Installing required packages ..."
pacman -S --noconfirm zsh git curl unzip

if [ -d "$USER_HOME/.oh-my-zsh" ]; then
    read -r -p "An existing .oh-my-zsh directory was found in $USER_HOME. Do you want to remove and reinstall it? (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$USER_HOME/.oh-my-zsh"
    else
        echo "Skipping reinstallation of Oh My Zsh."
    fi
fi

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh ..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    chsh -s "$(which zsh)" "$SUDO_USER"
else
    echo "Oh My Zsh is already installed, skipping installation."
fi

if [ -f "$USER_HOME/.zshrc" ]; then
    cp "$USER_HOME/.zshrc" "$USER_HOME/.zshrc.bak"
    echo "A backup of the existing .zshrc was created as .zshrc.bak."
    echo "Setting the theme in .zshrc to 'agnoster' ..."
    if grep -q '^ZSH_THEME=' "$USER_HOME/.zshrc"; then
        sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="agnoster"/' "$USER_HOME/.zshrc"
    else
        echo 'ZSH_THEME="agnoster"' >> "$USER_HOME/.zshrc"
    fi
else
    echo "Creating a new .zshrc with the theme 'agnoster' ..."
    echo 'ZSH_THEME="agnoster"' > "$USER_HOME/.zshrc"
fi

echo "Installing Powerline Fonts ..."
FONT_DIR="$USER_HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"

echo "Downloading Powerline Fonts ..."
curl -fsSL -o powerline-fonts.zip https://github.com/powerline/fonts/archive/refs/heads/master.zip

echo "Unpacking fonts ..."
unzip -q powerline-fonts.zip

if [ -d "fonts-master" ]; then
    cd fonts-master
    echo "Running the installation script for the fonts ..."
    ./install.sh
    cd ..
    rm -rf powerline-fonts.zip fonts-master
else
    echo "Error: The directory 'fonts-master' was not found after unpacking."
    exit 1
fi

echo "Resetting ownership rights in the home directory to $SUDO_USER ..."
chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME"

echo "Installation successful! Please restart your terminal or run 'exec zsh'."
