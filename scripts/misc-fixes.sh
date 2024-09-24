#!/usr/bin/bash
set -ouex pipefail

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
rm -rf /usr/share/icons/breeze-dark/status/22/fcitx.svg
rm -rf /usr/share/icons/breeze-dark/status/24/fcitx.svg

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

# Fix X display issues in distrobox
echo 'xhost +si:localuser:$USER >/dev/null' > /etc/skel/.distroboxrc

# Set some flatpak overrides
mkdir -p /var/lib/flatpak/overrides
echo '[Context]
filesystems=~/.themes;~/.icons;' | tee /var/lib/flatpak/overrides/global > /dev/null
echo '[Context]
sockets=!wayland;' | tee /var/lib/flatpak/overrides/dev.vencord.Vesktop /var/lib/flatpak/overrides/com.discordapp.Discord > /dev/null
