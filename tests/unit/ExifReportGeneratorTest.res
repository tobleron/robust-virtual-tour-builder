open ExifReportGenerator

let run = () => {
  Console.log("Running ExifReportGenerator tests...")

  // Debug regex
  let dt = "2025:01:15 14:30"
  let regex = /\\d{4}:\\d{2}:\\d{2}\\s+\\d{2}:\\d{2}/
  // In ReScript, if we use %re("/.../"), backslashes MUST be escaped if we want them in the final JS string?
  // Actually, %re("/") uses the same escaping as JS /.../

  // Let's test generateProjectName
  let addr = Some("123 Main St, Los Angeles, CA")
  let name = generateProjectName(addr, Some(dt))

  // If it still fails, I will use a regex that I know works in ReScript

  let expectedPrefix = "123_Main_St_150125_1430"
  if String.startsWith(name, expectedPrefix) {
    Console.log("✓ generateProjectName passed (full info)")
  } else {
    Console.error(`✗ generateProjectName failed: expected prefix ${expectedPrefix}, got ${name}`)
  }

  // Test 2: generateProjectName with no info
  let name2 = generateProjectName(None, None)
  if String.startsWith(name2, "Unknown_Location_") {
    Console.log("✓ generateProjectName passed (no info)")
  } else {
    Console.error(`✗ generateProjectName failed (no info): got ${name2}`)
  }

  // Test 3: generateProjectName with invalid date (should use today's date)
  let dt3 = Some("invalid-date")
  let name3 = generateProjectName(addr, dt3)

  // Today is Jan 15, 2026.
  if String.startsWith(name3, "123_Main_St_150126_") {
    Console.log("✓ generateProjectName passed (invalid date prefix)")
  } else {
    Console.error(`✗ generateProjectName failed (invalid date): got ${name3}`)
  }
}
