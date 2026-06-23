import ObjCDemoKit

guard let greeter = MakeObjCGreeter() else {
  fatalError("ObjCGreeter allocation failed")
}

greeter.logFoundationObjects()

if let message = greeter.messageCString() {
  print("Swift saw:", String(cString: message))
} else {
  print("Swift saw: <nil>")
}

print("Swift saw item count:", greeter.itemCount())

