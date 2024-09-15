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

# Install OpenH264 on first boot
SCRIPT_FILE="/usr/libexec/install-openh264"
cat <<EOF | sudo tee "$SCRIPT_FILE" > /dev/null
#!/usr/bin/bash
rpm-ostree install --assumeyes --apply-live openh264 mozilla-openh264 gstreamer1-plugin-openh264
systemctl disable install-openh264.service
EOF
chmod +x "$SCRIPT_FILE"

SERVICE_FILE="/etc/systemd/system/install-openh264.service"
cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Re-layer OpenH264 Codec
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/libexec/install-openh264
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable install-openh264.service
