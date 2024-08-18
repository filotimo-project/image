## 1. BUILD ARGS
# These allow changing the produced image by passing different build args to adjust
# the source from which your image is built.
# Build args can be provided on the commandline when building locally with:
#   podman build -f Containerfile --build-arg FEDORA_VERSION=40 -t local-image

# SOURCE_IMAGE arg can be anything from ublue upstream which matches your desired version:
# See list here: https://github.com/orgs/ublue-os/packages?repo_name=main
# - "silverblue"
# - "kinoite"
# - "sericea"
# - "onyx"
# - "lazurite"
# - "vauxite"
# - "base"
#
#  "aurora", "bazzite", "bluefin" or "ucore" may also be used but have different suffixes.
ARG SOURCE_IMAGE="kinoite"

## SOURCE_SUFFIX arg should include a hyphen and the appropriate suffix name
# These examples all work for silverblue/kinoite/sericea/onyx/lazurite/vauxite/base
# - "-main"
# - "-nvidia"
# - "-asus"
# - "-asus-nvidia"
# - "-surface"
# - "-surface-nvidia"
#
# aurora, bazzite and bluefin each have unique suffixes. Please check the specific image.
# ucore has the following possible suffixes
# - stable
# - stable-nvidia
# - stable-zfs
# - stable-nvidia-zfs
# - (and the above with testing rather than stable)
ARG SOURCE_SUFFIX="-main"

## SOURCE_TAG arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG SOURCE_TAG="40"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"

### 2. SOURCE IMAGE
## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/fsync-kernel:${FEDORA_MAJOR_VERSION} AS fsync
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

# fsync kernel
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=fsync,src=/tmp/rpms,dst=/tmp/fsync-rpms \
    rpm-ostree cliwrap install-to-root / && \
    rpm-ostree override replace \
    --experimental \
        /tmp/fsync-rpms/kernel-[0-9]*.rpm \
        /tmp/fsync-rpms/kernel-core-*.rpm \
        /tmp/fsync-rpms/kernel-modules-*.rpm \
        /tmp/fsync-rpms/kernel-uki-virt-*.rpm && \
    ostree container commit


# Install important repos
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    curl -Lo /etc/yum.repos.d/filotimo.repo https://download.opensuse.org/repositories/home:/tduck:/filotimolinux/Fedora_40/home:tduck:filotimolinux.repo && \
    curl -Lo /etc/yum.repos.d/klassy.repo https://download.opensuse.org/repositories/home:/paul4us/Fedora_40/home:paul4us.repo && \
    curl -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo && \
    ostree container commit

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install terra-release rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted && \
    ostree container commit

# Install Filotimo packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove zram-generator-defaults fedora-logos desktop-backgrounds-compat plasma-lookandfeel-fedora \
        --install filotimo-environment \
        --install filotimo-backgrounds \
        --install filotimo-branding \
        --install filotimo-kde-theme && \
    rpm-ostree install \
        filotimo-environment-fonts \
        filotimo-environment-ime \
        filotimo-environment-firefox \
        filotimo-kde-overrides \
        msttcore-fonts-installer \
        onedriver \
        appimagelauncher \
        filotimo-atychia \
        filotimo-grub-theme \
        filotimo-plymouth-theme && \
    ostree container commit

# Replace ppd with tuned
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        power-profiles-daemon \
        --install tuned \
        --install tuned-ppd && \
    ostree container commit

# Install misc. packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove noopenh264 --install openh264 && \
    rpm-ostree install \
        plasma-discover-rpm-ostree \
        distrobox \
        git \
        kdenetwork-filesharing \
        ksystemlog \
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
        gstreamer1-plugin-openh264 mozilla-openh264 \
        mesa-vdpau-drivers-freeworld mesa-va-drivers-freeworld \
        intel-media-driver libva-utils vdpauinfo \
        nvidia-vaapi-driver \
        libdvdcss \
        ffmpeg \
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
        htop \
        hplip \
        podman && \
    ostree container commit

### 3. MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

COPY build.sh /tmp/build.sh

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit
## NOTES:
# - /var/lib/alternatives is required to prevent failure with some RPM installs
# - All RUN commands must end with ostree container commit
#   see: https://coreos.github.io/rpm-ostree/container/#using-ostree-container-commit
