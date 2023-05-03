#!/bin/bash

#
# Build Arch Linux Package Repository
#
# This is a utility script to invoke `repo-add` with suitable defaults in
# a container setup. It runs on a readonly source-directory and uses /rae
# as workspace. Results are copied to the specified destination directory
# as super-user.
#

set -eo pipefail
shopt -s nullglob

# Variable declaration

X_DSTDIR=""
X_FILES=()
X_SRCDIR=""

# Parameter parsing

X_DSTDIR="$1"
X_SRCDIR="$2"

if [[ -z "${X_DSTDIR}" || -z "${X_SRCDIR}" ]] ; then
        echo >&2 "Usage: $0 <dst-dir> <src-dir>"
        exit 1
fi

# Build repository

mkdir -p "/rae/dst/repo"

X_FILES=("${X_SRCDIR}"/pkg-*/*.pkg.*)
if (( ${#X_FILES[@]} > 0 )) ; then
        cp "${X_FILES[@]}" "/rae/dst/repo/"
fi

repo-add \
        "/rae/dst/repo/repo.db.tar.gz" \
        /rae/dst/repo/*.pkg.*

# Since `repo-add` requires running as user, and containers still lack idmapped
# mounts, we simply copy all results to the destination directory as super
# user. This is not ideal, but at least it allows for a relatively simple
# setup.
sudo cp -r "/rae/dst/repo" "${X_DSTDIR}/"
