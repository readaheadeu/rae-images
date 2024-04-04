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
 * Target Groups
 *
 * The following section defines some custom target groups, which we use in
 * the CI system to rebuild a given set of images.
 *
 *     all-images
 *         Build all "product" images. That is, all images that are part of
 *         the project release and thus used by external entities.
 */

group "all-images" {
        targets = [
                "all-rae-aur-ci",
                "all-rae-zola",
        ]
}

/*
 * Virtual Base Targets
 *
 * This section defines virtual base targets, which are shared across the
 * different dependent targets.
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
