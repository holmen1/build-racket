#!/usr/bin/env bash

set -euxfo pipefail;

DOCKER_REPOSITORY="racket/racket";

# My repo
SECONDARY_DOCKER_REPOSITORY="holmen1/racket";

find_images () {
    declare -r repository="${1}";

    # Grab all of the racket images whose "tag"s start with a digit.
    docker images --format '{{.Repository}}:{{.Tag}}' | \
         (grep "^${repository}:[[:digit:]]" || true) | \
         sort;

    # Grab `latest` and `snapshot` images if available.
    docker images --format '{{.Repository}}:{{.Tag}}' | \
         (grep "^${repository}:\(latest\|snapshot\)" || true) | \
         sort;
}

find_testable_images () {
    declare -r repository="${1}";

    # Version 6.0 is ignored during test runs because its openssl
    # bindings are broken.
    #
    # xref: https://github.com/jackfirth/racket-docker/issues/35
    find_images "${repository}" | grep --invert-match "${repository}:6.0"
}
