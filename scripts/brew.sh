#!/usr/bin/bash
set -ouex pipefail

# Install prereqs
rpm-ostree install procps-ng curl file git gcc

# Convince the installer we are in CI
touch /.dockerenv

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Install brew
curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /tmp/brew-install
/tmp/brew-install
tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew
rm -rf /usr/share/homebrew.tar.zst
