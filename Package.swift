// swift-tools-version: 6.3

import PackageDescription

let gnustepPrefix = Context.environment["GNUSTEP_PREFIX"] ?? "/opt/openswift/gnustep"

let gnustepCompilerFlags = [
  "-fobjc-runtime=gnustep-2.0",
  "-fobjc-arc",
  "-fblocks",
  "-fconstant-string-class=NSConstantString",
  "-fexceptions",
  "-fobjc-exceptions",
  "-fPIC",
  "-pthread",
  "-DGNUSTEP",
  "-DGNUSTEP_BASE_LIBRARY=1",
  "-DGNUSTEP_RUNTIME=1",
  "-D_NONFRAGILE_ABI=1",
  "-D_NATIVE_OBJC_EXCEPTIONS",
  "-I\(gnustepPrefix)/include",
  "-I\(gnustepPrefix)/include/GNUstep",
]

let clangImporterFlags = gnustepCompilerFlags.flatMap { ["-Xcc", $0] }

let package = Package(
  name: "OpenSwiftProjectToolchainExample",
  products: [
    .executable(name: "GNUstepObjCDemo", targets: ["GNUstepObjCDemo"]),
  ],
  targets: [
    .target(
      name: "ObjCDemoKit",
      path: "DemoKit",
      sources: [
        "ObjCGreeter.m",
        // Known runtime workaround tracked by OpenSwiftProject/swift#2.
        "ObjCInteropShim.c",
        // Known selector ABI/IRGen workaround tracked by OpenSwiftProject/swift#3.
        "DarwinSelectorRefs.c",
      ],
      publicHeadersPath: ".",
      cSettings: [
        .unsafeFlags(gnustepCompilerFlags),
      ]
    ),
    .executableTarget(
      name: "GNUstepObjCDemo",
      dependencies: ["ObjCDemoKit"],
      path: "Sources/GNUstepObjCDemo",
      swiftSettings: [
        // Cross-cutting allocation gate tracked by swift#2 and swift#3.
        .define("OPEN_SWIFT_DEMOKIT_FACTORY_ISOLATION"),
        .unsafeFlags(["-Xfrontend", "-enable-objc-interop"] + clangImporterFlags),
      ],
      linkerSettings: [
        .unsafeFlags([
          "-L\(gnustepPrefix)/lib",
          "-Xlinker", "-rpath",
          "-Xlinker", "\(gnustepPrefix)/lib",
          "-Xlinker", "--export-dynamic",
          // Known class-symbol lowering workaround tracked by swift#3.
          "-Xlinker", "--defsym=OBJC_CLASS_$_ObjCGreeter=._OBJC_CLASS_ObjCGreeter",
        ]),
        .linkedLibrary("gnustep-base"),
        .linkedLibrary("objc"),
        .linkedLibrary("BlocksRuntime"),
        .linkedLibrary("dispatch"),
        .linkedLibrary("pthread"),
        .linkedLibrary("m"),
      ]
    ),
  ]
)
