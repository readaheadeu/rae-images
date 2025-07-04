/*
 * RAE_UNIQUEID - Unique Identifier
 *
 * If provided by the caller, this ID must be unique across all builds. It
 * is used to tag immutable images and make them available to external
 * users.
 *
 * If not provided (i.e., an empty string), no such unique tags will be pushed.
 *
 * A common way to generate this ID is to use UUIDs, or to use the current date
 * (e.g., `20210101`).
 *
 * Note that we strongly recommend external users to access images by digest
 * rather than this tag. We mostly use the unique tag to guarantee the image
 * stays available in the registry and is not garbage-collected.
 */

variable "RAE_UNIQUEID" {
        /*
         * XXX: This should be `null` instead of an empty string, but current
         *      `xbuild+HCL` does not support that.
         */
        default = ""
}

/*
 * Mirroring
 *
 * The custom `mirror()` function takes an image name, an image tag, an
 * optional tag-suffix, as well as an optional unique suffix. It then produces
 * an array of tags for all the configured hosts.
 *
 * If the unique suffix is not empty, an additional tag with the unique suffix
 * is added for each host (replacing the specified suffix). In other words,
 * this function concatenates the configured host with the specified image,
 * tag, "-" and suffix or unique-suffix. The dash is skipped if the suffix is
 * empty.
 */

function "mirror" {
        params = [image, tag, suffix, unique]

        result = flatten([
                for host in [
                        "ghcr.io/readaheadeu",
                ] : concat(
                        notequal(suffix, "") ?
                                ["${host}/${image}:${tag}-${suffix}"] :
                                ["${host}/${image}:${tag}"],
                        notequal(unique, "") ?
                                ["${host}/${image}:${tag}-${unique}"] :
                                [],
                )
        ])
}

/*
 * Groups
 */

group "all-images" {
        targets = [
                "all-rae-aur-ci",
                "all-rae-ci-archlinux",
                "all-rae-ci-ubuntu",
                "all-rae-lftp",
                "all-rae-zola",
        ]
}

/*
 * Virtual Targets
 */

target "virtual-default" {
        context = "."
        labels = {
                "org.opencontainers.image.source" = "https://github.com/readaheadeu/rae-images",
        }
}

target "virtual-platforms" {
        platforms = [
                "linux/amd64",
        ]
}

/*
 * rae-aur-ci
 */

group "all-rae-aur-ci" {
        targets = [
                "rae-aur-ci-latest",
        ]
}

target "virtual-rae-aur-ci" {
        dockerfile = "rae-aur-ci.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "rae-aur-ci-latest" {
        args = {
                RAE_FROM = "docker.io/library/archlinux:latest",
        }
        inherits = [
                "virtual-rae-aur-ci",
        ]
        tags = concat(
                mirror("rae-aur-ci", "latest", "", RAE_UNIQUEID),
        )
}

/*
 * rae-ci-archlinux
 */

group "all-rae-ci-archlinux" {
        targets = [
                "rae-ci-archlinux-latest",
        ]
}

target "virtual-rae-ci-archlinux" {
        dockerfile = "rae-ci-archlinux.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "rae-ci-archlinux-latest" {
        args = {
                RAE_FROM = "docker.io/library/archlinux:multilib-devel",
        }
        inherits = [
                "virtual-rae-ci-archlinux",
        ]
        tags = concat(
                mirror("rae-ci-archlinux", "latest", "", RAE_UNIQUEID),
        )
}

/*
 * rae-ci-ubuntu
 */

group "all-rae-ci-ubuntu" {
        targets = [
                "rae-ci-ubuntu-latest",
        ]
}

target "virtual-rae-ci-ubuntu" {
        dockerfile = "rae-ci-ubuntu.Dockerfile"
        inherits = [
                "virtual-default",
        ]
        platforms = [
                "linux/amd64",
                "linux/arm64",
        ]
}

target "rae-ci-ubuntu-latest" {
        args = {
                RAE_FROM = "docker.io/library/ubuntu:latest",
        }
        inherits = [
                "virtual-rae-ci-ubuntu",
        ]
        tags = concat(
                mirror("rae-ci-ubuntu", "latest", "", RAE_UNIQUEID),
        )
}

/*
 * rae-lftp
 */

group "all-rae-lftp" {
        targets = [
                "rae-lftp-latest",
        ]
}

target "virtual-rae-lftp" {
        dockerfile = "rae-lftp.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "rae-lftp-latest" {
        args = {
                RAE_FROM = "docker.io/library/alpine:latest",
        }
        inherits = [
                "virtual-rae-lftp",
        ]
        tags = concat(
                mirror("rae-lftp", "latest", "", RAE_UNIQUEID),
        )
}

/*
 * rae-zola
 */

group "all-rae-zola" {
        targets = [
                "rae-zola-latest",
        ]
}

target "virtual-rae-zola" {
        dockerfile = "rae-zola.Dockerfile"
        inherits = [
                "virtual-default",
                "virtual-platforms",
        ]
}

target "rae-zola-latest" {
        args = {
                RAE_FROM = "ghcr.io/getzola/zola:v0.18.0",
        }
        inherits = [
                "virtual-rae-zola",
        ]
        tags = concat(
                mirror("rae-zola", "latest", "", RAE_UNIQUEID),
        )
}
