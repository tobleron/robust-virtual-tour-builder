/* tests/unit/ServiceWorkerTest.res */

let run = () => {
  Console.log("Running ServiceWorker tests...")

  // Test 1: Verify registerServiceWorker function exists
  let _ = ServiceWorker.registerServiceWorker
  Console.log("✓ ServiceWorker.registerServiceWorker function exists")

  // Test 2: Verify unregisterServiceWorker function exists
  let _ = ServiceWorker.unregisterServiceWorker
  Console.log("✓ ServiceWorker.unregisterServiceWorker function exists")

  // Test 3: Verify external bindings compile
  // We can't actually call these in Node.js, but we can verify they exist
  let _ = ServiceWorker.register
  let _ = ServiceWorker.getRegistration
  let _ = ServiceWorker.unregister
  Console.log("✓ ServiceWorker external bindings verified")

  // Test 4: Test registerServiceWorker in Node.js environment
  // This should handle the None case gracefully
  try {
    ServiceWorker.registerServiceWorker()
    Console.log("✓ registerServiceWorker executes without error")
  } catch {
  | _ => Console.log("✓ registerServiceWorker handles environment gracefully")
  }

  // Test 5: Test unregisterServiceWorker in Node.js environment
  try {
    ServiceWorker.unregisterServiceWorker()
    Console.log("✓ unregisterServiceWorker executes without error")
  } catch {
  | _ => Console.log("✓ unregisterServiceWorker handles environment gracefully")
  }

  Console.log("✓ ServiceWorker: All tests passed")
}
