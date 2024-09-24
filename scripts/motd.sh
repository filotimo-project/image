#!/usr/bin/bash
set -ouex pipefail

# Setup MOTD
BOLD='\033[1m'
LIGHT_BLUE='\033[1;34m'
RESET='\033[0m'
printf "${BOLD}Welcome to the filotimo terminal :)${RESET}

This is a ${LIGHT_BLUE}rpm-ostree${RESET} based system, so many terminal commands may work differently to how you're used to, as the base system is immutable.

A container-based workflow is recommended, since the base system is read only.
To do things that need a read and write system, create a distrobox.
A distrobox is a container that can have any distribution installed within it, and is integrated with your system.
Run this to create a distrobox:
${LIGHT_BLUE}distrobox create --image registry.fedoraproject.org/fedora-toolbox:40 --name my-distrobox${RESET}
To find out more, visit ${BOLD}https://github.com/89luca89/distrobox${RESET}.

To install terminal utilities to the base system, use ${LIGHT_BLUE}brew${RESET}, which only installs into your home folder.

To install graphical applications, use Flatpaks or AppImages.
Flatpaks can be easily installed in Discover and through the terminal with the ${LIGHT_BLUE}flatpak${RESET} command, and AppImageLauncher is included with the system for easy integration.
If strictly necessary, you can install normal Fedora .rpm packages with ${LIGHT_BLUE}rpm-ostree${RESET}, but this is not recommended.

Many utility scripts are included with the system.
To view these scripts, use the ${LIGHT_BLUE}ujust${RESET} command.
Scripts to install a KDE development environment are included.

${LIGHT_BLUE}fish${RESET} is the default shell on filotimo, which works differently to ${LIGHT_BLUE}bash${RESET} and is not fully POSIX-compliant. To learn more, visit ${BOLD}https://fishshell.com/docs/current/${RESET}.
To change the ${LIGHT_BLUE}fish${RESET} theme and other options, use the ${LIGHT_BLUE}fish_config${RESET} command.
${LIGHT_BLUE}fish${RESET} is wrapped with ${LIGHT_BLUE}fishlogin${RESET}, ensuring ${BOLD}/etc/profile${RESET} still works as you'd expect.

To disable/re-enable this message, type:
${LIGHT_BLUE}ujust toggle-user-motd${RESET}
----------------------------------------------------------------------------------\n" > /etc/user-motd
