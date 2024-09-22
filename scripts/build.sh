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

# Fix up GRUB
sed -i 's/GRUB_TERMINAL_OUTPUT="console"/GRUB_TERMINAL_OUTPUT="gfxterm"/' /etc/default/grub
echo "GRUB_THEME=\"/boot/grub2/themes/filotimo/theme.txt\"" >> /etc/default/grub

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
