#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$ROOT_DIR/DemoKit"
BUILD_DIR="${OPEN_SWIFT_DEMOKIT_BUILD_DIR:-$ROOT_DIR/.build/demokit}"

TOOLCHAIN="${OPEN_SWIFT_TOOLCHAIN:-${TOOLCHAIN:-/opt/openswift/swift-6.3-gnustep/usr}}"
PREFIX="${GNUSTEP_PREFIX:-${PREFIX:-/opt/openswift/gnustep}}"

if [[ ! -x "$TOOLCHAIN/bin/swiftc" ]]; then
  echo "error: swiftc not found at $TOOLCHAIN/bin/swiftc" >&2
  echo "Set OPEN_SWIFT_TOOLCHAIN or use scripts/run-demokit.sh --local-artifacts." >&2
  exit 1
fi

if [[ ! -x "$PREFIX/bin/gnustep-config" ]]; then
  echo "error: gnustep-config not found at $PREFIX/bin/gnustep-config" >&2
  echo "Set GNUSTEP_PREFIX or use scripts/run-demokit.sh --local-artifacts." >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"

export LD_LIBRARY_PATH="$TOOLCHAIN/lib/swift/linux:$TOOLCHAIN/lib:$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CPATH="$PREFIX/include:$PREFIX/include/GNUstep:${CPATH:-}"
export LIBRARY_PATH="$PREFIX/lib:${LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"

echo "== Swift compiler =="
"$TOOLCHAIN/bin/swiftc" --version

echo "== GNUstep prefix =="
echo "$PREFIX"

OBJCFLAGS="$("$PREFIX/bin/gnustep-config" --objc-flags)"
BASELIBS="$("$PREFIX/bin/gnustep-config" --base-libs)"

echo "== Build Objective-C demo library =="
"$TOOLCHAIN/bin/clang" $OBJCFLAGS \
  -fobjc-runtime=gnustep-2.0 \
  -fobjc-arc \
  -fblocks \
  -fPIC \
  -I"$DEMO_DIR" \
  -I"$PREFIX/include" \
  -I"$PREFIX/include/GNUstep" \
  -c "$DEMO_DIR/ObjCGreeter.m" \
  -o "$BUILD_DIR/ObjCGreeter.o"

"$TOOLCHAIN/bin/clang" \
  -fPIC \
  -I"$PREFIX/include" \
  -c "$DEMO_DIR/ObjCInteropShim.c" \
  -o "$BUILD_DIR/ObjCInteropShim.o"

"$TOOLCHAIN/bin/clang" \
  -fPIC \
  -I"$PREFIX/include" \
  -c "$DEMO_DIR/DarwinSelectorRefs.c" \
  -o "$BUILD_DIR/DarwinSelectorRefs.o"

"$TOOLCHAIN/bin/clang" \
  -shared "$BUILD_DIR/ObjCGreeter.o" "$BUILD_DIR/ObjCInteropShim.o" \
  -o "$BUILD_DIR/libObjCDemoKit.so" \
  $BASELIBS \
  -L"$PREFIX/lib" \
  -lobjc \
  -lBlocksRuntime \
  -ldispatch \
  '-Wl,--defsym=OBJC_CLASS_$_ObjCGreeter=._OBJC_CLASS_ObjCGreeter' \
  -Wl,-rpath,"$PREFIX/lib"

read -r -a OBJCFLAG_ARRAY <<< "$OBJCFLAGS"
SWIFT_XCC=()
for flag in "${OBJCFLAG_ARRAY[@]}"; do
  SWIFT_XCC+=(-Xcc "$flag")
done

echo "== Build Swift executable =="
"$TOOLCHAIN/bin/swiftc" \
  -Xfrontend -enable-objc-interop \
  -I "$DEMO_DIR" \
  -I "$BUILD_DIR" \
  "${SWIFT_XCC[@]}" \
  -Xcc -fobjc-runtime=gnustep-2.0 \
  -Xcc -fblocks \
  -Xcc -I"$DEMO_DIR" \
  -Xcc -I"$PREFIX/include" \
  -Xcc -I"$PREFIX/include/GNUstep" \
  -L "$BUILD_DIR" \
  -lObjCDemoKit \
  -L "$PREFIX/lib" \
  -lobjc \
  -lgnustep-base \
  -lBlocksRuntime \
  -ldispatch \
  -Xlinker -rpath \
  -Xlinker "$BUILD_DIR" \
  -Xlinker -rpath \
  -Xlinker "$PREFIX/lib" \
  "$BUILD_DIR/DarwinSelectorRefs.o" \
  "$DEMO_DIR/main.swift" \
  -o "$BUILD_DIR/GNUstepObjCDemo"

echo "== Run DemoKit =="
"$BUILD_DIR/GNUstepObjCDemo"

