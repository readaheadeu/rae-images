#
# rae-ci-archlinux - Common Readahead.eu Arch Linux CI Image
#
# A shared Arch Linux image designed for CI environments of software projects.
# It has common toolchains and dependencies pre-installed.
#
# Arguments:
#
#   * RAE_FROM="docker.io/library/archlinux:multilib-devel"
#       This controls the host container used as base for the CI image.
#

ARG             RAE_FROM="docker.io/library/archlinux:multilib-devel"
FROM            "${RAE_FROM}" AS target

#
# Prepare the target environment. Import required sources from the build
# context, but ensure to drop them afterwards.
#

WORKDIR         /rae/sys

# Install required packages
RUN             echo -e "[core-debug]\nInclude = /etc/pacman.d/mirrorlist" >>/etc/pacman.conf
RUN             pacman -Sy --noconfirm
RUN             pacman -Su --noconfirm
RUN             pacman -S --needed --noconfirm \
                        audit \
                        clang \
                        coreutils \
                        curl \
                        dbus \
                        expat \
                        gcc-libs \
                        git \
                        glib2 \
                        glibc \
                        glibc-debug \
                        htop \
                        jq \
                        libcap-ng \
                        lld \
                        meson \
                        procps-ng \
                        python-docutils \
                        rust-bindgen \
                        rustup \
                        strace \
                        systemd \
                        systemd-libs \
                        tar \
                        tree \
                        util-linux \
                        valgrind \
                        vim \
                        \
                        lib32-audit \
                        lib32-dbus \
                        lib32-expat \
                        lib32-gcc-libs \
                        lib32-glib2 \
                        lib32-glibc \
                        lib32-systemd

# Enable git workaround
RUN             git config --system --add safe.directory '*'

# Add `runner` as a user and group.
RUN             useradd -ms /bin/bash -g users -G wheel runner
RUN             echo "runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN             chpasswd <<<"root:root"
RUN             chpasswd <<<"runner:runner"

# Create `/rae/runner`, chown it, and switch to the new user.
RUN             mkdir -p /rae/runner
RUN             chown -R "runner:users" /rae/runner
WORKDIR         /rae/runner
USER            runner:users

# Install Rust via `rustup`.
RUN             mkdir -p /rae/runner/sys/{cargo,rustup}
ENV             CARGO_HOME=/rae/runner/sys/cargo
ENV             RUSTUP_HOME=/rae/runner/sys/rustup
RUN             rustup toolchain install \
                        --component cargo,clippy,miri,rust-std,rustc \
                        --profile minimal \
                        --target i686-unknown-linux-gnu,x86_64-unknown-linux-gnu \
                        nightly
RUN             rustup toolchain install \
                        --component cargo,clippy,rust-std,rustc \
                        --profile minimal \
                        --target i686-unknown-linux-gnu,x86_64-unknown-linux-gnu \
                        stable
RUN             rustup default stable

# Create some default directories for the user.
RUN             mkdir -p /rae/runner/{build,src,workdir}

#
# Rebuild from scratch to drop all intermediate layers and keep the final image
# as small as possible. Then setup the entrypoint.
#

FROM            scratch
COPY            --from=target . .

ENV             CARGO_HOME=/rae/runner/sys/cargo
ENV             RUSTUP_HOME=/rae/runner/sys/rustup

USER            runner:users
WORKDIR         /rae/runner/workdir
