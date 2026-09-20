# OpenSwiftProject Toolchain Example

This repository is a self-contained smoke test for the current OpenSwiftProject Swift 6.3 + GNUstep Objective-C interop toolchain work.

It builds a tiny Objective-C GNUstep module, imports it from Swift with
`-enable-objc-interop -objc-runtime-vendor=gnustep`, and runs the result inside a
Docker toolchain image. This revision requires GNUstep class-symbol and selector
lowering in the Swift frontend; it supplies neither per-class ELF linker aliases
nor a selector-registration shim.

## Quick Start

Use the published `6.3-alpha.3` image (Ubuntu 24.04, Linux ARM64), which includes
GNUstep class-symbol and selector lowering:

```sh
git clone https://github.com/OpenSwiftProject/toolchain-example.git
cd toolchain-example
./scripts/run-demokit.sh \
  --image ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha.3
```

The [release workflow](https://github.com/OpenSwiftProject/toolchain-docker/actions/runs/34049285226)
validated both this example and the built-in fixture in Debug and Release,
including SwiftPM build/run/test, selector-only DSOs, the manual runner, and
anonymous image pull. Older images without the compiler fixes cannot run this
revision.

The runner defaults to the moving alpha alias below and only pulls missing
images. To refresh an already-cached alias, explicitly run `docker pull` first;
use the immutable `6.3-alpha.3` tag above for a reproducible run.

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
Swift verified GNUstep selectors
```

## Swift Package Build, Run, and Test

`Package.swift` expresses the demo as the same two-target shape used by a
normal Darwin package:

- `GNUstepObjCDemo`, a Swift executable target
- `ObjCDemoKit`, an Objective-C/Clang target used by the executable

It also includes `GNUstepObjCDemoTests`, a Swift integration-test target. Its
XCTest and Swift Testing cases each launch the built demo and assert the real
Objective-C/Foundation output. The target intentionally does not directly
depend on `ObjCDemoKit`: SwiftPM's generated test-discovery targets do not yet
inherit the target-scoped GNUstep Objective-C importer flags.

Run SwiftPM inside the published Linux toolchain. From the repository root:

```sh
docker run --rm --platform linux/arm64 \
  --mount "type=bind,src=$PWD,dst=/workspace/toolchain-example" \
  --workdir /workspace/toolchain-example \
  ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha.3 \
  bash -c 'swift build && swift run GNUstepObjCDemo && swift test'
```

This writes SwiftPM build products to the checkout's ignored `.build` directory.
For both Debug and Release, run these commands inside the container:

```sh
swift build
swift run GNUstepObjCDemo
swift test
swift build --configuration release
swift run --configuration release GNUstepObjCDemo
swift test --configuration release
```

The published SwiftPM-enabled toolchain installs
`swift-package`, `swift-build`, `swift-run`, `swift-test`, LLBuild, IndexStore,
XCTest, Swift Testing, and SwiftPM's manifest runtime. This package has been
validated through both Debug and Release `swift build`/`swift run`/`swift test`
workflows with that image. Both the SwiftPM and manual runners now require a
frontend with GNUstep class-symbol and selector lowering; the manual runner is not a
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

The toolchain Docker build lives in a separate repository:

```text
OpenSwiftProject/toolchain-docker
```

Primary GHCR image names:

```text
ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha-ubuntu24-aarch64
ghcr.io/openswiftproject/swift-gnustep-toolchain:6.3-alpha
```

This example can build or refresh the image from that repository before running:

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

- `DemoKit/ObjCInteropShim.c` temporarily provides missing Swift runtime Objective-C metadata entry points. Track removal in [OpenSwiftProject/swift#2](https://github.com/OpenSwiftProject/swift/issues/2).

Per-class `--defsym` aliases are no longer used. The GNUstep frontend mode loads
the `._OBJC_REF_CLASS_*` slots exported by Clang's GNUstep ABI v2 providers.

`DarwinSelectorRefs.c` is also removed. The compiler emits writable GNUstep
selector records in `__objc_selectors`, registered by the Clang-generated image
initializer. Class/instance messages, property getters/setters, multi-argument
selectors, and repeated selectors in separate Swift source files are exercised.
Both workaround removals shipped in `6.3-alpha.3` under
[OpenSwiftProject/swift#3](https://github.com/OpenSwiftProject/swift/issues/3);
they are no longer pending demo-side fixes.

Source-level `#selector` also requires the Swift `ObjectiveC` module/overlay,
which this Linux toolchain does not yet install. Native selector literal IR is
covered separately; this example does not claim the complete Darwin Selector API.
Track the platform/overlay gap in
[OpenSwiftProject/swift#1](https://github.com/OpenSwiftProject/swift/issues/1).

The remaining runtime shim marks the metadata work still needed in the toolchain.

SwiftPM keeps `OPEN_SWIFT_DEMOKIT_FACTORY_ISOLATION` enabled, using
`MakeObjCGreeter()` for allocation while runtime metadata support is incomplete.
The manual runner uses direct Swift `ObjCGreeter()` allocation, which also passes
with the remaining runtime shim. This limited result does not establish general
runtime metadata correctness or support for Swift-defined `@objc` classes and
subclasses.
The factory-isolation gate is shared follow-up under
[OpenSwiftProject/swift#2](https://github.com/OpenSwiftProject/swift/issues/2) and
[OpenSwiftProject/swift#3](https://github.com/OpenSwiftProject/swift/issues/3),
not another selector-registration workaround.

Directly importing `ObjCDemoKit` from a SwiftPM test target is also not yet a
supported claim. The current integration tests exercise the real executable
boundary while generated test-target importer settings and the remaining
runtime interop gaps are tracked separately.
See [the package-workflow tracker](https://github.com/OpenSwiftProject/toolchain-docker/issues/2)
and [the remaining example workarounds](https://github.com/OpenSwiftProject/toolchain-example/issues/1).

## Scripts

```text
scripts/run-demokit.sh
scripts/build-demokit-in-container.sh
scripts/prepare-toolchain-image.sh
```
