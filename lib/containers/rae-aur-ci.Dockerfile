#
# rae-aur-ci - Readahead.eu AUR CI Image
#
# A minimal Arch Linux image for the AUR CI of Readahead.eu. It is based on
# the official Arch Linux base image plus a set of required packages for
# package operations.
#
# Arguments:
#
#   * RAE_FROM="docker.io/library/archlinux:latest"
#       This controls the host container used as base for the CI image.
#

ARG             RAE_FROM="docker.io/library/archlinux:latest"
FROM            "${RAE_FROM}" AS target

#
# Prepare the target environment. Import required sources from the build
# context, but ensure to drop them afterwards.
#

WORKDIR         /rae

RUN             pacman -Sy --noconfirm
RUN             pacman -Su --noconfirm
RUN             pacman -S --needed --noconfirm base-devel

RUN             useradd -ms /bin/bash -g users -G wheel builder
RUN             echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN             chpasswd <<<"root:root"
RUN             chpasswd <<<"builder:builder"

RUN             mkdir -p /rae/{build,dst,src,util}
COPY            ./util/buildpkg.sh /rae/util/
COPY            ./util/buildrepo.sh /rae/util/
RUN             chown -R "builder:users" /rae

#
# Rebuild from scratch to drop all intermediate layers and keep the final image
# as small as possible. Then setup the entrypoint.
#

FROM            scratch
COPY            --from=target . .

USER            builder:users
WORKDIR         /rae/workdir
