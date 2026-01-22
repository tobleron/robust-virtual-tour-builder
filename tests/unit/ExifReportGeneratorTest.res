open ExifReportGenerator

let run = () => {
  Console.log("Running ExifReportGenerator tests...")

  // Debug regex
  let dt = "2025:01:15 14:30"
  let _regex = /\\d{4}:\\d{2}:\\d{2}\\s+\\d{2}:\\d{2}/
  // In ReScript, if we use %re("/.../"), backslashes MUST be escaped if we want them in the final JS string?
  // Actually, %re("/") uses the same escaping as JS /.../

  // Let's test generateProjectName
  let addr = Some("123 Main St, Los Angeles, CA")
  let nameResult = generateProjectName(addr, Some(dt))

  let expectedPrefix = "123_Main_St_150125_1430"
  switch nameResult {
  | Some(name) if String.startsWith(name, expectedPrefix) =>
    Console.log("✓ generateProjectName passed (full info)")
  | Some(name) =>
    Console.error(`✗ generateProjectName failed: expected prefix ${expectedPrefix}, got ${name}`)
  | None => Console.error(`✗ generateProjectName failed: got None, expected ${expectedPrefix}`)
  }

  // Test 2: generateProjectName with no info (should return fallback)
  let name2Result = generateProjectName(None, None)
  switch name2Result {
  | Some(name) if String.startsWith(name, "Tour_") =>
    Console.log("✓ generateProjectName passed (no info returns Tour fallback)")
  | Some(name) =>
    Console.error(`✗ generateProjectName failed (no info): expected Tour fallback, got ${name}`)
  | None =>
    Console.error(`✗ generateProjectName failed (no info): expected Tour fallback, got None`)
  }

  // Test 3: generateProjectName with invalid date (should use today's date)
  let dt3 = Some("invalid-date")
  let name3Result = generateProjectName(addr, dt3)

  // Calculate today's expected prefix: DDMMYY
  let now = Date.make()
  let pad = n => n < 10 ? "0" ++ Int.toString(n) : Int.toString(n)
  let day = now->Date.getDate->pad
  let month = (now->Date.getMonth + 1)->pad
  let year = (now->Date.getFullYear - 2000)->pad
  let expectedTodayPrefix = day ++ month ++ year

  switch name3Result {
  | Some(name) if String.startsWith(name, "123_Main_St_" ++ expectedTodayPrefix ++ "_") =>
    Console.log("✓ generateProjectName passed (invalid date prefix)")
  | Some(name) =>
    Console.error(
      `✗ generateProjectName failed (invalid date): got ${name}, expected prefix matching ${expectedTodayPrefix}`,
    )
  | None => Console.error(`✗ generateProjectName failed (invalid date): got None`)
  }
}
