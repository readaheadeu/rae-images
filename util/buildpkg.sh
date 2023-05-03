#!/bin/bash

#
# Build Arch Linux Packages
#
# This is a utility script to invoke `makepkg` with suitable defaults in
# a container setup. It runs on a readonly source-directory and uses /rae
# as workspace. Results are copied to the specified destination directory
# as super-user.
#

set -eo pipefail

# Variable declaration

X_ARGS=()
X_DSTDIR=""
X_SRCDIR=""

# Parameter parsing

X_DSTDIR="$1"
X_SRCDIR="$2"
X_ARGS=("${@:3}")

if [[ -z "${X_DSTDIR}" || -z "${X_SRCDIR}" ]] ; then
        echo >&2 "Usage: $0 <dst-dir> <src-dir> <makepkg-args...>"
        exit 1
fi

# Build package

# `makepkg` calls `fakeroot`, which cannot properly deal with unlimited NOFILE
# settings, so reset it to the historical default.
ulimit -Sn 1024

env \
        --chdir "${X_SRCDIR}" \
        BUILDDIR="/rae/build" \
        LOGDEST="/rae/dst" \
        PKGDEST="/rae/dst" \
        SRCDEST="/rae/src" \
        SRCPKGDEST="/rae/dst" \
        makepkg \
                --force \
                --needed \
                --noconfirm \
                "$X_ARGS"

# Since `makepkg` requires running as user, and containers still lack idmapped
# mounts, we simply copy all results to the destination directory as super
# user. This is not ideal, but at least it allows for a relatively simple
# setup.
sudo cp -r "/rae/dst/." "${X_DSTDIR}/"
