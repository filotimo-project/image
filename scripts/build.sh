#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Enable samba for filesharing
systemctl enable smb

# Enable tuned
systemctl enable tuned
systemctl enable tuned-ppd

# Mask hibernate - usually just causes problems
systemctl mask hibernate.target

# Fix podman complaining about some database thing
mkdir -p /etc/skel/.local/share/containers/storage/volumes

# Hide nvtop and htop desktop entries
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/htop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/nvtop.desktop

# Set Konsole default profile
echo "[Desktop Entry]
DefaultProfile=Filotimo.profile" >> /etc/xdg/konsolerc

# Set rpm-ostree to check for updates automatically, not stage automatically
# Updates will be done automatically by Discover
sed -i "s/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=check/" /etc/rpm-ostreed.conf

# Remove fcitx default icons
rm -rf /usr/share/icons/breeze/status/22/fcitx.svg
rm -rf /usr/share/icons/breeze/status/24/fcitx.svg

# Fix up GRUB TODO doesn't work
sed -i 's/GRUB_TERMINAL_OUTPUT="console"/GRUB_TERMINAL_OUTPUT="gfxterm"/' /etc/default/grub
echo "GRUB_THEME=\"/boot/grub2/themes/filotimo/theme.txt\"" >> /etc/default/grub

# Fix misconfigured samba usershares
mkdir -p /var/lib/samba/usershares
chown -R root:usershares /var/lib/samba/usershares
firewall-offline-cmd --service=samba --service=samba-client

# Helper for virt-manager
cat <<-EOF | tee /usr/libexec/selinux-virt-manager > /dev/null
#!/usr/bin/bash
set -e
kdialog --warningcontinuecancel "The SELinux security module included with this operating system may cause compatibility issues with Virtual Machine Manager. Continuing will temporarily disable SELinux until the next reboot, or until the command\nsudo setenforce 1\nis executed in a terminal.\n" --title "Security Warning"
pkexec setenforce 0
virt-manager
EOF
chmod +x /usr/libexec/selinux-virt-manager
sed -i 's@^Exec=.*@Exec=/usr/libexec/selinux-virt-manager@' /usr/share/applications/virt-manager.desktop

# Fix GTK theming
mkdir -p /etc/skel/.config/gtk-3.0 /etc/skel/.config/gtk-4.0
touch /etc/skel/.config/gtk-3.0/settings.ini /etc/skel/.config/gtk-4.0/settings.ini
echo "[Settings]
gtk-application-prefer-dark-theme=false
gtk-button-images=true
gtk-cursor-theme-name=breeze_cursors
gtk-cursor-theme-size=24
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=true
gtk-font-name=Inter Variable,  10
gtk-icon-theme-name=breeze
gtk-menu-images=true
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-primary-button-warps-slider=true
gtk-sound-theme-name=ocean
gtk-theme-name=Breeze
gtk-toolbar-style=3
gtk-xft-dpi=98304" > /etc/skel/.config/gtk-3.0/settings.ini
echo "[Settings]
gtk-application-prefer-dark-theme=false
gtk-cursor-theme-name=breeze_cursors
gtk-cursor-theme-size=24
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=true
gtk-font-name=Inter Variable,  10
gtk-icon-theme-name=breeze
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-primary-button-warps-slider=true
gtk-sound-theme-name=ocean
gtk-theme-name=Breeze
gtk-xft-dpi=98304" > /etc/skel/.config/gtk-4.0/settings.ini

# Install OpenH264 on first boot
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/fedora-cisco-openh264.repo
SCRIPT_FILE="/usr/libexec/postinstall-install-openh264"
cat <<EOF | tee "$SCRIPT_FILE" > /dev/null
#!/usr/bin/bash
if rpm-ostree status | grep -q 'openh264\|mozilla-openh264\|gstreamer1-plugin-openh264'; then
    echo "OpenH264 is already layered."
else
    echo "One or more OpenH264 packages were not layered, installing now..."
    rpm-ostree override remove noopenh264 --install openh264 --install mozilla-openh264 --install gstreamer1-plugin-openh264
    echo "Changes will take effect on next reboot."
fi
EOF
chmod +x "$SCRIPT_FILE"
SERVICE_FILE="/etc/systemd/system/postinstall-install-openh264.service"
cat <<EOF | tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Re-layer OpenH264 Codec
After=network-online.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_FILE
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable postinstall-install-openh264.service

# Install brew
# Convince the installer we are in CI
touch /.dockerenv

# Make these so script will work
mkdir -p /var/home
mkdir -p /var/roothome

# Brew Install Script
curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /tmp/brew-install
/tmp/brew-install
tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew

# Install Starship Shell Prompt
curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc
echo 'eval "$(starship init zsh)"' >> /etc/zshrc

# ...and also add bash preexec
curl -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

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
To find out more, visit ${LIGHT_BLUE}https://github.com/89luca89/distrobox${RESET}

To install terminal utilities to the base system, use ${LIGHT_BLUE}brew${RESET}, which only installs into your home folder.

To install graphical applications, use Flatpaks or AppImages.
Flatpaks can be easily installed in Discover and through the terminal with the ${LIGHT_BLUE}flatpak${RESET} command, and AppImageLauncher is included with the system for easy integration.
If strictly necessary, you can install normal Fedora .rpm packages with ${LIGHT_BLUE}rpm-ostree${RESET}, but this is not recommended.

Many utility scripts are included with the system.
To view these scripts, use the ${LIGHT_BLUE}ujust${RESET} command.
Scripts to install a KDE development environment are included.

To disable this message, type:
${LIGHT_BLUE}ujust toggle-user-motd${RESET}\n\n" > /etc/user-motd

# Fix X display issues in distrobox
echo 'xhost +si:localuser:$USER >/dev/null' > /etc/skel/.distroboxrc
