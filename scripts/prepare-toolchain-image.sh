#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${1:-${OPEN_SWIFT_TOOLCHAIN_IMAGE:-openswiftproject/swift-gnustep-toolchain:6.3-alpha-ubuntu24-aarch64}}"
REPO_URL="${2:-${OPEN_SWIFT_TOOLCHAIN_DOCKER_REPO:-https://github.com/OpenSwiftProject/toolchain-docker.git}}"
CHECKOUT_DIR="${OPEN_SWIFT_TOOLCHAIN_DOCKER_CHECKOUT:-$ROOT_DIR/.cache/toolchain-docker}"

if [[ -d "$CHECKOUT_DIR/.git" ]]; then
  git -C "$CHECKOUT_DIR" fetch --all --tags
  git -C "$CHECKOUT_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$CHECKOUT_DIR")"
  git clone "$REPO_URL" "$CHECKOUT_DIR"
fi

if [[ -x "$CHECKOUT_DIR/scripts/build-image.sh" ]]; then
  OPEN_SWIFT_TOOLCHAIN_IMAGE="$IMAGE" "$CHECKOUT_DIR/scripts/build-image.sh"
elif [[ -f "$CHECKOUT_DIR/Dockerfile" ]]; then
  docker build -t "$IMAGE" "$CHECKOUT_DIR"
else
  echo "error: $CHECKOUT_DIR does not contain scripts/build-image.sh or Dockerfile" >&2
  exit 1
fi

