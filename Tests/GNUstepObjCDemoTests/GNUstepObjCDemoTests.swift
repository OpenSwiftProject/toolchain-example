import Foundation
import Testing
import XCTest

private struct DemoExecutionError: Error {
  let status: Int32
  let output: String
}

private func runGNUstepObjCDemo() throws -> String {
  let testExecutable = URL(fileURLWithPath: CommandLine.arguments[0])
  let demoExecutable = testExecutable
    .deletingLastPathComponent()
    .appendingPathComponent("GNUstepObjCDemo")
  let outputPipe = Pipe()
  let process = Process()

  process.executableURL = demoExecutable
  process.standardOutput = outputPipe
  process.standardError = outputPipe
  try process.run()

  let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  let output = String(decoding: outputData, as: UTF8.self)
  guard process.terminationStatus == 0 else {
    throw DemoExecutionError(status: process.terminationStatus, output: output)
  }
  return output
}

private func outputContainsExpectedValues(_ output: String) -> Bool {
  output.contains("ObjCGreeter: Hello from GNUstep Objective-C (4 items)")
    && output.contains("Swift saw: Hello from GNUstep Objective-C")
    && output.contains("Swift saw item count: 4")
}

@Test("Swift Testing runs the GNUstep Objective-C demo")
func swiftTestingRunsGNUstepObjectiveCDemo() throws {
  let output = try runGNUstepObjCDemo()
  #expect(outputContainsExpectedValues(output))
  print("Swift Testing verified swift test")
}

final class GNUstepObjCDemoXCTest: XCTestCase {
  func testXCTestRunsGNUstepObjectiveCDemo() throws {
    let output = try runGNUstepObjCDemo()
    XCTAssertTrue(outputContainsExpectedValues(output), output)
    print("XCTest verified swift test")
  }
}
