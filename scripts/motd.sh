#!/usr/bin/bash
set -ouex pipefail

# Setup MOTD
cat <<'EOF'> /usr/libexec/ublue-motd
BOLD='\033[1m'
LIGHT_BLUE='\033[1;34m'
RESET='\033[0m'
echo -e "${BOLD}Welcome to the filotimo terminal :)${RESET}

This is a ${LIGHT_BLUE}rpm-ostree${RESET} based system, so many terminal commands may work differently to how you're used to, as the base system is immutable.

A container-based workflow is recommended, since the base system is read only.
To do things that need a read and write system, create a distrobox.
A distrobox is a container that can have any distribution installed within it, and is integrated with your home folder.
To create a distrobox, run ${LIGHT_BLUE}distrobox create --image registry.fedoraproject.org/fedora-toolbox:40 --name my-distrobox${RESET}
Visit ${BOLD}https://github.com/89luca89/distrobox${RESET} to find out more.

To install terminal utilities to the base system, use ${LIGHT_BLUE}brew${RESET}.

To install graphical applications, use Flatpaks or AppImages.
Flatpaks can be easily installed in Discover and through the terminal with the ${LIGHT_BLUE}flatpak${RESET} command, and AppImageLauncher is included with the system for easy integration.
You can install normal Fedora .rpm packages with ${LIGHT_BLUE}rpm-ostree${RESET}, but this is not recommended.

Many utility scripts are included with the system.
To view these scripts, use the ${LIGHT_BLUE}ujust${RESET} command.

${LIGHT_BLUE}fish${RESET} is the default shell on filotimo, which works differently to ${LIGHT_BLUE}bash${RESET} and is not fully POSIX-compliant. To learn more, visit ${BOLD}https://fishshell.com/docs/current/${RESET} or simply type ${LIGHT_BLUE}help${RESET}.
Many shell scripts do not work with fish. If this is the case, you can simply type ${LIGHT_BLUE}bash${RESET} in a terminal to use ${LIGHT_BLUE}bash${RESET}.
You can also change your login shell to ${LIGHT_BLUE}bash${RESET} with ${LIGHT_BLUE}sudo usermod --shell bash \$USER${RESET}.
${LIGHT_BLUE}fish${RESET} is wrapped with ${LIGHT_BLUE}fishlogin${RESET} ensuring ${BOLD}/etc/profile${RESET} still assigns environment variables.

To disable/re-enable this message, type:
${LIGHT_BLUE}ujust toggle-user-motd${RESET}
----------------------------------------------------------------------------------\n"
EOF
chmod +x /usr/libexec/ublue-motd
