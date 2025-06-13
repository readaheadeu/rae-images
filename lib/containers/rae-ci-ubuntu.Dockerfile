#
# rae-ci-ubuntu - Common Readahead.eu Ubuntu CI Image
#
# A shared Arch Linux image designed for CI environments of software projects.
# It has common toolchains and dependencies pre-installed.
#
# Arguments:
#
#   * CAB_FROM="docker.io/library/ubuntu:latest"
#       This controls the host container used as base for the CI image.
#

ARG             CAB_FROM="docker.io/library/ubuntu:latest"
FROM            "${CAB_FROM}" AS target

#
# Import our build sources and prepare the target environment. When finished,
# we drop the build sources again, to keep the target image small.
#

WORKDIR         /rae/sys

# Install required packages
ENV             DEBIAN_FRONTEND="noninteractive"
RUN             apt-get clean
RUN             apt-get update
RUN             apt-get upgrade -y
RUN             apt-get install -y \
                        --no-install-recommends \
                        -- \
                                "apparmor" \
                                "bash" \
                                "bindgen" \
                                "binutils-dev" \
                                "build-essential" \
                                "ca-certificates" \
                                "clang" \
                                "coreutils" \
                                "curl" \
                                "dbus-daemon" \
                                "debianutils" \
                                "file" \
                                "findutils" \
                                "flex" \
                                "gawk" \
                                "gcc" \
                                "gdb" \
                                "gettext" \
                                "git" \
                                "grep" \
                                "groff" \
                                "gzip" \
                                "htop" \
                                "iproute2" \
                                "jq" \
                                "libapparmor-dev" \
                                "libasan8" \
                                "libaudit-dev" \
                                "libbison-dev" \
                                "libc-dev" \
                                "libcap-ng-dev" \
                                "libclang-dev" \
                                "libclang-rt-dev" \
                                "libdbus-1-dev" \
                                "libexpat-dev" \
                                "libglib2.0-dev" \
                                "libselinux-dev" \
                                "libsystemd-dev" \
                                "libubsan1" \
                                "lld" \
                                "make" \
                                "meson" \
                                "ninja-build" \
                                "patch" \
                                "pkgconf" \
                                "procps" \
                                "pylint" \
                                "python3-clang" \
                                "python3-docutils" \
                                "python3-dev" \
                                "python3-mako" \
                                "python3-pip" \
                                "python3-pytest" \
                                "qemu-system-x86" \
                                "qemu-utils" \
                                "rustup" \
                                "sed" \
                                "strace" \
                                "sudo" \
                                "systemd" \
                                "tar" \
                                "texinfo" \
                                "util-linux" \
                                "valgrind" \
                                "vim"
RUN             apt-get clean
RUN             rm -rf /var/lib/apt/lists/*

# Enable Bash
SHELL           ["/bin/bash", "-c"]

# Enable git workaround
RUN             git config --system --add safe.directory '*'

# Add `runner` as a user and group.
RUN             useradd -ms /bin/bash -g users runner
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
