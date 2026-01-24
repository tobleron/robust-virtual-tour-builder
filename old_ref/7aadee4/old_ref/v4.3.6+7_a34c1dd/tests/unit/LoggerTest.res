// open Logger removed to avoid shadowing

let run = () => {
  Console.log("Running Logger tests...")

  // Test 1: Level Priority
  if (
    Logger.levelPriority(Trace) < Logger.levelPriority(Info) &&
      Logger.levelPriority(Error) > Logger.levelPriority(Info)
  ) {
    Console.log("✓ levelPriority passed")
  } else {
    Console.error("✗ levelPriority failed")
  }

  // Test 2: Level String conversions
  if (
    Logger.levelToString(Debug) == "debug" &&
    Logger.stringToLevel("error") == Error &&
    Logger.stringToLevel("unknown") == Info
  ) {
    Console.log("✓ Level string conversions passed")
  } else {
    Console.error("✗ Level string conversions failed")
  }

  // Test 3: timed operation
  let timedResult = Logger.timed(~module_="Test", ~operation="test_op", () => {
    let _ = 1 + 1
    "done"
  })
  if timedResult.result == "done" && timedResult.durationMs >= 0.0 {
    Console.log("✓ timed operation passed")
  } else {
    Console.error("✗ timed operation failed")
  }

  // Test 4: attempt operation (Success)
  let successResult = Logger.attempt(~module_="Test", ~operation="success_op", () => "ok")
  switch successResult {
  | Ok("ok") => Console.log("✓ attempt success path passed")
  | _ => Console.error("✗ attempt success path failed")
  }

  // Test 5: attempt operation (Failure)
  let failResult = Logger.attempt(~module_="Test", ~operation="fail_op", () => {
    %raw(`(function(){ throw new Error("test error") })()`)
  })
  switch failResult {
  | Error("test error") => Console.log("✓ attempt failure path passed")
  | Error(msg) => Console.error(`✗ attempt failure path failed: got different message: ${msg}`)
  | Ok(_) => Console.error("✗ attempt failure path failed: expected Error, got Ok")
  }

  Console.log("✓ Logger: Module logic verified")
}
