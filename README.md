# OpenSwiftProject Toolchain Example

This repository is a self-contained smoke test for the current OpenSwiftProject Swift 6.3 + GNUstep Objective-C interop toolchain work.

It builds a tiny Objective-C GNUstep module, imports it from Swift with `-enable-objc-interop`, and runs the result inside a Docker toolchain image.

## Quick Start

Use the primary GHCR alpha image:

```sh
git clone https://github.com/OpenSwiftProject/toolchain-example.git
cd toolchain-example
./scripts/run-demokit.sh
```

Default image:

```text
ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha-ubuntu24-aarch64
```

Expected output:

```text
ObjCGreeter: Hello from GNUstep Objective-C (4 items)
Swift saw: Hello from GNUstep Objective-C
Swift saw item count: 4
```

## Run With Local Artifacts

If you have a locally built Swift toolchain and GNUstep prefix, point the example at those artifacts:

```sh
./scripts/run-demokit.sh \
  --local-artifacts \
  --toolchain /Volumes/Workspace/OpenSwiftProject/swift-toolchain-root/usr \
  --prefix /Volumes/Workspace/OpenSwiftProject/prefix \
  --base-image gnustep-bootstrap-ubuntu24
```

The local-artifacts mode mounts those paths into the container at:

```text
/opt/openswift/swift-6.3-gnustep/usr
/opt/openswift/gnustep
```

## Build The Toolchain Image Locally

The toolchain Docker build should live in a separate repository:

```text
OpenSwiftProject/toolchain-docker
```

Primary GHCR image names:

```text
ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha-ubuntu24-aarch64
ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha
```

When that repository exists, this example can build or refresh the image before running:

```sh
./scripts/run-demokit.sh \
  --build-image \
  --toolchain-docker-repo https://github.com/OpenSwiftProject/toolchain-docker.git
```

You can override the image name:

```sh
OPEN_SWIFT_TOOLCHAIN_IMAGE=ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha \
  ./scripts/run-demokit.sh
```

## What The Demo Covers

The Objective-C side uses:

- `NSObject`
- `NSString`
- `NSArray`
- `NSLog`
- ARC
- Blocks

The Swift side imports the Objective-C module and calls Objective-C methods:

```swift
import ObjCDemoKit

guard let greeter = MakeObjCGreeter() else {
  fatalError("ObjCGreeter allocation failed")
}
greeter.logFoundationObjects()

if let message = greeter.messageCString() {
  print("Swift saw:", String(cString: message))
}
print("Swift saw item count:", greeter.itemCount())
```

## Current Alpha Limitations

This example contains demo-side shims for the current bootstrap toolchain. They are intentionally visible:

- `DemoKit/ObjCInteropShim.c` temporarily provides missing Swift runtime Objective-C metadata entry points.
- `DemoKit/DarwinSelectorRefs.c` registers Swift-emitted Darwin-style selector references with GNUstep/libobjc2.
- The shared library links an ELF alias from `OBJC_CLASS_$_ObjCGreeter` to GNUstep's `._OBJC_CLASS_ObjCGreeter`.

These shims mark the Swift runtime and IRGen work that still needs to move into the toolchain.

## Scripts

```text
scripts/run-demokit.sh
scripts/build-demokit-in-container.sh
scripts/prepare-toolchain-image.sh
```
