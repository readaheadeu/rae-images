#
# rae-zola - Zola SSG Mirror
#
# This image mirrors the official Zola SSG images.
#
# Arguments:
#
#  * RAE_FROM="ghcr.io/getzola/zola:v0.18.0"
#       This controls the host container used as base for the image.
#

ARG     RAE_FROM="ghcr.io/getzola/zola:v0.18.0"
FROM    "${RAE_FROM}"
