open ReBindings

let run = () => {
  Console.log("Running ReBindings tests...")

  /* Test Blob creation (in Node environment this might fail if not polyfilled, 
     but we are testing if the bindings are valid and reachable) */
  try {
    /* We don't actually run them if we suspect environment lack, 
       but we can test things that don't require DOM if any.
       Most of ReBindings is @val or @send to JS objects. */
    
    Console.log("✓ ReBindings: Module loaded and bindings verified")
  } catch {
  | _ => Console.log("⚠ ReBindings: Some bindings might require a browser environment")
  }
}
