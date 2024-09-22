ARG IMAGE_NAME="${IMAGE_NAME:-filotimo}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fsync}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite-main}"
ARG SOURCE_ORG="${SOURCE_ORG:-ublue-os}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-filotimo}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"

FROM ghcr.io/ublue-os/${KERNEL_FLAVOR}-kernel:${FEDORA_MAJOR_VERSION} AS kernel
FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION} AS akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION} AS akmods-extra

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as filotimo

ARG IMAGE_NAME="${IMAGE_NAME:-filotimo}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fsync}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite-main}"
ARG SOURCE_ORG="${SOURCE_ORG:-ublue-os}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-filotimo}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"

# fsync kernel - remove for f41 once upstream ublue ships it TODO
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=kernel,src=/tmp/rpms,dst=/tmp/fsync-rpms \
    rpm-ostree cliwrap install-to-root / && \
    rpm-ostree override replace \
    --experimental \
        /tmp/fsync-rpms/kernel-[0-9]*.rpm \
        /tmp/fsync-rpms/kernel-core-*.rpm \
        /tmp/fsync-rpms/kernel-modules-*.rpm \
        /tmp/fsync-rpms/kernel-uki-virt-*.rpm && \
    ostree container commit

# Install akmod rpms for various firmware and features
# add and disable negativo immediately due to incompatibility with RPMFusion although it's required for akmods
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /usr/bin/copr https://raw.githubusercontent.com/ublue-os/COPR-command/main/copr && \
    chmod +x /usr/bin/copr && \
    curl -Lo /etc/yum.repos.d/_copr_hikariknight-looking-glass-kvmfr.repo https://copr.fedorainfracloud.org/coprs/hikariknight/looking-glass-kvmfr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/hikariknight-looking-glass-kvmfr-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/_copr_rok-cdemu.repo https://copr.fedorainfracloud.org/coprs/rok/cdemu/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rok-cdemu-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/*kvmfr*.rpm \
        /tmp/akmods-rpms/kmods/*xone*.rpm \
        /tmp/akmods-rpms/kmods/*openrazer*.rpm \
        /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm \
        /tmp/akmods-rpms/kmods/*wl*.rpm \
        /tmp/akmods-rpms/kmods/*framework-laptop*.rpm \
        /tmp/akmods-extra-rpms/kmods/*gcadapter_oc*.rpm \
        /tmp/akmods-extra-rpms/kmods/*nct6687*.rpm \
        /tmp/akmods-extra-rpms/kmods/*zenergy*.rpm \
        /tmp/akmods-extra-rpms/kmods/*vhba*.rpm \
        /tmp/akmods-extra-rpms/kmods/*ayaneo-platform*.rpm \
        /tmp/akmods-extra-rpms/kmods/*ayn-platform*.rpm \
        /tmp/akmods-extra-rpms/kmods/*bmi260*.rpm \
        /tmp/akmods-extra-rpms/kmods/*ryzen-smu*.rpm \
        /tmp/akmods-extra-rpms/kmods/*evdi*.rpm && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_hikariknight-looking-glass-kvmfr.repo && \
    ostree container commit

# Some realtek firmware that I don't really know about
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    mkdir -p /tmp/mediatek-firmware && \
    curl -Lo /tmp/mediatek-firmware/WIFI_MT7922_patch_mcu_1_1_hdr.bin "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/8f08053b2a7474e210b03dbc2b4ba59afbe98802/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin?inline=false" && \
    curl -Lo /tmp/mediatek-firmware/WIFI_RAM_CODE_MT7922_1.bin "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/8f08053b2a7474e210b03dbc2b4ba59afbe98802/mediatek/WIFI_RAM_CODE_MT7922_1.bin?inline=false" && \
    xz --check=crc32 /tmp/mediatek-firmware/WIFI_MT7922_patch_mcu_1_1_hdr.bin && \
    xz --check=crc32 /tmp/mediatek-firmware/WIFI_RAM_CODE_MT7922_1.bin && \
    mv -vf /tmp/mediatek-firmware/* /usr/lib/firmware/mediatek/ && \
    rm -rf /tmp/mediatek-firmware && \
    ostree container commit

# Install important repos
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    echo "${FEDORA_MAJOR_VERSION}" && \
    curl -Lo /etc/yum.repos.d/filotimo.repo https://download.opensuse.org/repositories/home:/tduck:/filotimolinux/Fedora_"${FEDORA_MAJOR_VERSION}"/home:tduck:filotimolinux.repo && \
    curl -Lo /etc/yum.repos.d/klassy.repo https://download.opensuse.org/repositories/home:/paul4us/Fedora_"${FEDORA_MAJOR_VERSION}"/home:paul4us.repo && \
    curl -Lo /etc/yum.repos.d/_copr_rodoma92-kde-cdemu-manager.repo https://copr.fedorainfracloud.org/coprs/rodoma92/kde-cdemu-manager/repo/fedora-"${FEDORA_MAJOR_VERSION}"/rodoma92-kde-cdemu-manager-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo && \
    rpm-ostree install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted && \
    ostree container commit

# Install Filotimo packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rm -rf /var/cache/rpm-ostree/repomd && \
    rpm-ostree override remove zram-generator-defaults fedora-logos desktop-backgrounds-compat plasma-lookandfeel-fedora \
        --install filotimo-environment \
        --install filotimo-backgrounds \
        --install filotimo-branding \
        --install filotimo-kde-theme && \
    rpm-ostree install \
        filotimo-grub-theme \
        filotimo-environment-firefox \
        filotimo-environment-fonts \
        filotimo-environment-ime \
        filotimo-kde-overrides \
        msttcore-fonts-installer \
        onedriver \
        appimagelauncher \
        bup kup python-libfuse \
        filotimo-atychia \
        filotimo-plymouth-theme && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/terra.repo && \
    ostree container commit

# Replace ppd with tuned - remove for f41 TODO
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        power-profiles-daemon \
        --install tuned \
        --install tuned-ppd && \
    ostree container commit

# Install misc. packages
# libdvdcss has dubious legality
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        ublue-os-update-services \
        toolbox kcron && \
    rpm-ostree install \
        plasma-discover-rpm-ostree \
        distrobox \
        git gh \
        nodejs-bash-language-server \
        kdenetwork-filesharing \
        ark \
        kio-admin \
        kleopatra \
        firewall-config \
        setroubleshoot \
        openssl openssl-libs \
        python3-pip \
        nmap \
        i2c-tools \
        dmidecode \
        pulseaudio-utils \
        p7zip \
        p7zip-plugins \
        unzip \
        unrar \
        libheif libheif-tools \
        gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-vaapi \
        x265 \
        ffmpeg \
        mesa-vdpau-drivers-freeworld mesa-va-drivers-freeworld \
        intel-media-driver libva-intel-driver libva-utils vdpauinfo \
        libdvdcss vlc \
        kde-cdemu-manager-kf6 \
        v4l2loopback pipewire-v4l2 libcamera-v4l2 \
        samba samba-usershares samba-dcerpc samba-ldb-ldap-modules samba-winbind-clients samba-winbind-modules \
        rclone \
        mesa-libGLU \
        usbmuxd \
        stress-ng \
        epson-inkjet-printer-escpr \
        epson-inkjet-printer-escpr2 \
        foomatic \
        foomatic-db-ppds \
        gutenprint \
        libimobiledevice \
        hplip \
        htop \
        virt-manager \
        podman && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_rok-cdemu.repo && \
    ostree container commit

# Add modifications and finalize
COPY scripts/build.sh /tmp/build.sh
COPY scripts/build-initramfs.sh /tmp/build-initramfs.sh
COPY scripts/image-info.sh /tmp/image-info.sh

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    /tmp/build-initramfs.sh && \
    IMAGE_FLAVOR=main /tmp/image-info.sh && \
    ostree container commit

FROM ghcr.io/ublue-os/akmods-nvidia:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION} AS nvidia-akmods

FROM filotimo as filotimo-nvidia

ARG IMAGE_NAME="${IMAGE_NAME:-filotimo-nvidia}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-fsync}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite-main}"
ARG SOURCE_ORG="${SOURCE_ORG:-ublue-os}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${BASE_IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-filotimo}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"

# Install NVIDIA driver, use different copr repo for kf6 supergfxctl plasmoid
# TODO only install supergfxctl on hybrid systems or find some way to only show it on hybrid systems
# it's confusing visual noise outside of that context
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=nvidia-akmods,src=/rpms,dst=/tmp/akmods-rpms \
    curl -Lo /etc/yum.repos.d/_copr_jhyub-supergfxctl-plasmoid.repo https://copr.fedorainfracloud.org/coprs/jhyub/supergfxctl-plasmoid/repo/fedora-"${FEDORA_MAJOR_VERSION}"/jhyub-supergfxctl-plasmoid-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="kinoite" /tmp/nvidia-install.sh && \
    rpm-ostree install nvidia-vaapi-driver && \
    systemctl enable supergfxd && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_jhyub-supergfxctl-plasmoid.repo && \
    ostree container commit

COPY scripts/build-initramfs.sh /tmp/build-initramfs.sh
COPY scripts/image-info.sh /tmp/image-info.sh
# For less ugly supergfxctl icons
COPY scripts/integrate-supergfxctl-plasmoid.sh /tmp/integrate-supergfxctl-plasmoid.sh
COPY scripts/supergfxctl-icons /tmp/supergfxctl-icons

# Finalize
RUN /tmp/build-initramfs.sh && \
    IMAGE_FLAVOR=nvidia /tmp/image-info.sh && \
    cd /tmp && ./integrate-supergfxctl-plasmoid.sh && \
    ostree container commit
