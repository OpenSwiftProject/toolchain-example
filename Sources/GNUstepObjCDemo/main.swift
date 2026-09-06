import ObjCDemoKit

// Force references to several classes, including classes defined in a shared
// library, so class-symbol lowering is tested without per-class linker aliases.
print("Swift saw class:", String(cString: ObjCDemoClassName(ObjCGreeter.self)))
print("Swift saw class:", String(cString: ObjCDemoClassName(NSString.self)))
print("Swift saw class:", String(cString: ObjCDemoClassName(NSObject.self)))

#if OPEN_SWIFT_DEMOKIT_FACTORY_ISOLATION
guard let greeter = MakeObjCGreeter() else {
  fatalError("ObjCGreeter allocation failed")
}
#else
guard let greeter = ObjCGreeter() else {
  fatalError("ObjCGreeter allocation failed")
}
#endif

greeter.logFoundationObjects()

if let message = greeter.messageCString() {
  print("Swift saw:", String(cString: message))
} else {
  print("Swift saw: <nil>")
}

print("Swift saw item count:", greeter.itemCount())
checkSelectors(greeter)
