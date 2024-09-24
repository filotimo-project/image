#!/usr/bin/bash

# Symlink to Breeze theme for some redundant icons
ln -sf /usr/share/icons/breeze/actions/22/system-suspend.svg /usr/share/icons/breeze/status/22/supergfxctl-plasmoid-dgpu-suspended.svg
ln -sf /usr/share/icons/breeze/status/22/battery-profile-performance.svg /usr/share/icons/breeze/status/22/supergfxctl-plasmoid-dgpu-active.svg
ln -sf /usr/share/icons/breeze/actions/22/system-shutdown.svg /usr/share/icons/breeze/status/22/supergfxctl-plasmoid-dgpu-off.svg

# Copy better icons
cp ./supergfxctl-icons/* /usr/share/icons/breeze/status/22/
