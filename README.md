# OpenSwiftProject Toolchain Example

This repository is a self-contained smoke test for the current OpenSwiftProject Swift 6.3 + GNUstep Objective-C interop toolchain work.

It builds a tiny Objective-C GNUstep module, imports it from Swift with
`-enable-objc-interop -objc-runtime-vendor=gnustep`, and runs the result inside a
Docker toolchain image. This revision requires the imported-class symbol fix in
the Swift frontend; it no longer supplies per-class ELF linker aliases.

## Quick Start

Use a locally built image containing the GNUstep class-symbol lowering fix:

```sh
git clone https://github.com/OpenSwiftProject/toolchain-example.git
cd toolchain-example
OPEN_SWIFT_TOOLCHAIN_IMAGE=openswift/class-symbols:test ./scripts/run-demokit.sh
```

The runner's default image is still the published alpha tag below. Older images
without `-objc-runtime-vendor=gnustep` cannot build this revision; override the
image until an updated toolchain is published.

```text
ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha-ubuntu24-aarch64
```

If GHCR is slow from your network, you can rewrite the default image through a GHCR-compatible mirror host:

```sh
./scripts/run-demokit.sh --ghcr-mirror <ghcr_mirror>
```

The same setting is available as an environment variable: `OPEN_SWIFT_GHCR_MIRROR=<ghcr_mirror>`.

For example, users in mainland China may try: `ghcr.nju.edu.cn`.

Expected output:

```text
ObjCGreeter: Hello from GNUstep Objective-C (4 items)
Swift saw class: ObjCGreeter
Swift saw class: NSString
Swift saw class: NSObject
Swift saw: Hello from GNUstep Objective-C
Swift saw item count: 4
```

## Swift Package Experiment

`Package.swift` expresses the demo as the same two-target shape used by a
normal Darwin package:

- `GNUstepObjCDemo`, a Swift executable target
- `ObjCDemoKit`, an Objective-C/Clang target used by the executable

It also includes `GNUstepObjCDemoTests`, a Swift integration-test target. Its
XCTest and Swift Testing cases each launch the built demo and assert the real
Objective-C/Foundation output. The target intentionally does not directly
depend on `ObjCDemoKit`: SwiftPM's generated test-discovery targets do not yet
inherit the target-scoped GNUstep Objective-C importer flags.

The intended toolchain experience is:

```sh
swift build
swift run GNUstepObjCDemo
swift test
```

The matching SwiftPM-enabled `toolchain-docker` workspace installs
`swift-package`, `swift-build`, `swift-run`, `swift-test`, LLBuild, IndexStore,
XCTest, Swift Testing, and SwiftPM's manifest runtime. This package has been
validated through both Debug and Release `swift build`/`swift run`/`swift test`
workflows with that image. Both the SwiftPM and manual runners now require a
frontend with GNUstep class-symbol lowering; the manual runner is not a
compatibility fallback for older published images.

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

It also passes `ObjCGreeter.self`, `NSString.self`, and `NSObject.self` to an
Objective-C helper and verifies the class names. This exercises class references
to both the package's Objective-C target and the shared GNUstep Foundation
library. These are non-generic classes: generic metatype lookup is a separate
runtime-metadata path, not coverage of direct class-symbol lowering.

## Current Alpha Limitations

This example contains demo-side shims for the current bootstrap toolchain. They are intentionally visible:

- `DemoKit/ObjCInteropShim.c` temporarily provides missing Swift runtime Objective-C metadata entry points.
- `DemoKit/DarwinSelectorRefs.c` registers Swift-emitted Darwin-style selector references with GNUstep/libobjc2.

Per-class `--defsym` aliases are no longer used. The GNUstep frontend mode loads
the `._OBJC_REF_CLASS_*` slots exported by Clang's GNUstep ABI v2 providers.

These shims mark the Swift runtime and IRGen work that still needs to move into the toolchain.

SwiftPM keeps `OPEN_SWIFT_DEMOKIT_FACTORY_ISOLATION` enabled, using
`MakeObjCGreeter()` for allocation while runtime metadata support is incomplete.
The manual runner uses direct Swift `ObjCGreeter()` allocation, which also passes
with the two remaining shims. This limited result does not establish general
runtime metadata correctness or support for Swift-defined `@objc` classes and
subclasses.

Directly importing `ObjCDemoKit` from a SwiftPM test target is also not yet a
supported claim. The current integration tests exercise the real executable
boundary while generated test-target importer settings and the remaining
runtime interop gaps are tracked separately.

## Scripts

```text
scripts/run-demokit.sh
scripts/build-demokit-in-container.sh
scripts/prepare-toolchain-image.sh
```
