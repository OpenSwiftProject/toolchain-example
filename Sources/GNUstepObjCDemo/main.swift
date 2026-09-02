import ObjCDemoKit

#if OPEN_SWIFT_DEMOKIT_FACTORY_ISOLATION
guard let greeter = MakeObjCGreeter() else {
  fatalError("ObjCGreeter allocation failed")
}
#else
let greeter = ObjCGreeter()
#endif

greeter.logFoundationObjects()

if let message = greeter.messageCString() {
  print("Swift saw:", String(cString: message))
} else {
  print("Swift saw: <nil>")
}

print("Swift saw item count:", greeter.itemCount())
