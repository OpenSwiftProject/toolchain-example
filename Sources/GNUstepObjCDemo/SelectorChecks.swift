import ObjCDemoKit

// A separate Swift file also exercises selector coalescing across object files
// in Debug builds (and across functions under Release whole-module builds).
func checkSelectors(_ greeter: ObjCGreeter) {
  precondition(greeter.itemCount() == 4)
  precondition(greeter.add(19, to: 23) == 42)
  greeter.selectorProbeValue = 42
  precondition(greeter.selectorProbeValue == 42)
  precondition(String(cString: ObjCGreeter.classMessageCString())
    == "GNUstep class selector")
  print("Swift verified GNUstep selectors")
}
