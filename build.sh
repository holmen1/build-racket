#!/usr/bin/env bash

set -euxfo pipefail;

case "${1:-x}" in
  8x) declare -r series="8x" ;;
  snapshot) declare -r series="snapshot" ;;

  *) echo "usage: $0 [8x|snapshot]"
     exit 1
     ;;
esac

source "_common.sh";

build_base () {
  docker image build \
         --file "base.Dockerfile" \
         --tag "base" \
         .;
}

build () {
  declare -r dockerfile_name="${1}";
  declare -r installer_url="${2}";
  declare -r version="${3}";
  declare -r image_name="${4}";
  declare -r tag="${DOCKER_REPOSITORY}:${image_name}";
  declare -r secondary_tag="${SECONDARY_DOCKER_REPOSITORY}:${image_name}";

  docker image build \
      --file "${dockerfile_name}.Dockerfile" \
      --tag "${DOCKER_REPOSITORY}:${image_name}" \
      --build-arg "RACKET_INSTALLER_URL=${installer_url}" \
      --build-arg "RACKET_VERSION=${version}" \
      .;

  docker image tag "${tag}" "${secondary_tag}";
};

installer_url () {
  declare -r version="${1}";
  declare -r installer_path="${2}";
  echo "https://download.racket-lang.org/installers/${version}/${installer_path}";
};

build_snapshot () {
  declare -r version="snapshot";

  declare -r installer="https://users.cs.utah.edu/plt/snapshots/current/installers/racket-minimal-current-x86_64-linux-jesse.sh";
  build "racket" "${installer}" "${version}" "${version}";

  declare -r full_installer="https://users.cs.utah.edu/plt/snapshots/current/installers/racket-current-x86_64-linux-jesse.sh";
  build "racket" "${full_installer}" "${version}" "${version}-full";
}

build_8 () {
  declare -r version="${1}";

  declare -r installer_path="racket-minimal-${version}-x86_64-linux-natipkg.sh";
  declare -r installer=$(installer_url "${version}" "${installer_path}") || exit "${?}";
  build "racket" "${installer}" "${version}" "${version}";

  declare -r full_installer_path="racket-${version}-x86_64-linux-natipkg.sh";
  declare -r full_installer=$(installer_url "${version}" "${full_installer_path}") || exit "${?}";
  build "racket" "${full_installer}" "${version}" "${version}-full";
};

declare -r LATEST_RACKET_VERSION="8.12";

tag_latest () {
  declare -r repository="${1}";
  docker image tag "${repository}:${LATEST_RACKET_VERSION}" "${repository}:latest";
};

build_8x () {
  build_8 "${LATEST_RACKET_VERSION}";
  tag_latest "${DOCKER_REPOSITORY}";
  tag_latest "${SECONDARY_DOCKER_REPOSITORY}";
}

build_base;

case "$series" in
  8x) build_8x ;;
  snapshot) build_snapshot ;;
esac
