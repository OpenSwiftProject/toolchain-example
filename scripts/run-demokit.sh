#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

IMAGE="${OPEN_SWIFT_TOOLCHAIN_IMAGE:-ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha-ubuntu24-aarch64}"
PLATFORM="${OPEN_SWIFT_DOCKER_PLATFORM:-linux/arm64}"
BASE_IMAGE="${OPEN_SWIFT_BASE_IMAGE:-gnustep-bootstrap-ubuntu24}"
TOOLCHAIN_DOCKER_REPO="${OPEN_SWIFT_TOOLCHAIN_DOCKER_REPO:-https://github.com/OpenSwiftProject/toolchain-docker.git}"
PULL_POLICY="${OPEN_SWIFT_DOCKER_PULL:-missing}"
LOCAL_ARTIFACTS=0
BUILD_IMAGE=0
HOST_TOOLCHAIN="${OPEN_SWIFT_HOST_TOOLCHAIN:-}"
HOST_PREFIX="${OPEN_SWIFT_HOST_GNUSTEP_PREFIX:-}"

usage() {
  cat <<'EOF'
Usage:
  scripts/run-demokit.sh [options]

Options:
  --image IMAGE                 Docker toolchain image to run.
  --platform PLATFORM           Docker platform. Default: linux/arm64.
  --no-pull                     Do not ask Docker to pull missing images.
  --build-image                 Build the toolchain image from toolchain-docker before running.
  --toolchain-docker-repo URL   Git URL for OpenSwiftProject/toolchain-docker.
  --local-artifacts             Mount a locally built Swift toolchain and GNUstep prefix.
  --toolchain PATH              Host path to Swift toolchain root, ending in /usr.
  --prefix PATH                 Host path to GNUstep install prefix.
  --base-image IMAGE            Base image for --local-artifacts mode.
  -h, --help                    Show this help.

Examples:
  scripts/run-demokit.sh

  scripts/run-demokit.sh \
    --local-artifacts \
    --toolchain /Volumes/Workspace/OpenSwiftProject/swift-toolchain-root/usr \
    --prefix /Volumes/Workspace/OpenSwiftProject/prefix \
    --base-image gnustep-bootstrap-ubuntu24
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      IMAGE="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --no-pull)
      PULL_POLICY="never"
      shift
      ;;
    --build-image)
      BUILD_IMAGE=1
      shift
      ;;
    --toolchain-docker-repo)
      TOOLCHAIN_DOCKER_REPO="$2"
      shift 2
      ;;
    --local-artifacts)
      LOCAL_ARTIFACTS=1
      shift
      ;;
    --toolchain)
      HOST_TOOLCHAIN="$2"
      shift 2
      ;;
    --prefix)
      HOST_PREFIX="$2"
      shift 2
      ;;
    --base-image)
      BASE_IMAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$BUILD_IMAGE" -eq 1 ]]; then
  "$ROOT_DIR/scripts/prepare-toolchain-image.sh" "$IMAGE" "$TOOLCHAIN_DOCKER_REPO"
fi

DOCKER_ARGS=(
  run
  --rm
  --platform "$PLATFORM"
  -v "$ROOT_DIR:/workspace/toolchain-example"
  -w /workspace/toolchain-example
)

if [[ "$LOCAL_ARTIFACTS" -eq 1 ]]; then
  if [[ -z "$HOST_TOOLCHAIN" || -z "$HOST_PREFIX" ]]; then
    echo "error: --local-artifacts requires --toolchain and --prefix" >&2
    exit 1
  fi
  if [[ ! -x "$HOST_TOOLCHAIN/bin/swiftc" ]]; then
    echo "error: local swiftc not found at $HOST_TOOLCHAIN/bin/swiftc" >&2
    exit 1
  fi
  if [[ ! -x "$HOST_PREFIX/bin/gnustep-config" ]]; then
    echo "error: local gnustep-config not found at $HOST_PREFIX/bin/gnustep-config" >&2
    exit 1
  fi

  DOCKER_ARGS+=(
    -v "$HOST_TOOLCHAIN:/opt/openswift/swift-6.3-gnustep/usr:ro"
    -v "$HOST_PREFIX:/opt/openswift/gnustep:ro"
    -e OPEN_SWIFT_TOOLCHAIN=/opt/openswift/swift-6.3-gnustep/usr
    -e GNUSTEP_PREFIX=/opt/openswift/gnustep
    "$BASE_IMAGE"
  )
else
  DOCKER_ARGS+=(
    --pull "$PULL_POLICY"
    -e OPEN_SWIFT_TOOLCHAIN=/opt/openswift/swift-6.3-gnustep/usr
    -e GNUSTEP_PREFIX=/opt/openswift/gnustep
    "$IMAGE"
  )
fi

DOCKER_ARGS+=(
  bash
  -lc
  "./scripts/build-demokit-in-container.sh"
)

docker "${DOCKER_ARGS[@]}"
