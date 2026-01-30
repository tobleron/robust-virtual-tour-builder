/* src/systems/ExifReportGenerator.res - Consolidated EXIF Report Generation System */

/* Logic extracted to ExifReportGeneratorLogic.res */
include ExifReportGeneratorLogic

/* Main Generator Function (kept here as Orchestrator) */
let generateExifReport = async (sceneDataList: array<sceneDataItem>) => {
  Logger.initialized(~module_="ExifReportGenerator")
  let lines = []

  let _ = Array.push(
    lines,
    "╔══════════════════════════════════════════════════════════════════════════════╗",
  )
  let _ = Array.push(
    lines,
    "║                          EXIF METADATA ANALYSIS REPORT                       ║",
  )
  let _ = Array.push(
    lines,
    "╠══════════════════════════════════════════════════════════════════════════════╣",
  )

  let now = Date.make()
  let dateStr = Date.toLocaleString(now)
  let padded = String.padEnd(dateStr, 63, " ")
  let _ = Array.push(lines, `║  Generated: ${padded}║`)

  let count = Belt.Int.toString(Array.length(sceneDataList))
  let countPadded = String.padEnd(count, 52, " ")
  let _ = Array.push(lines, `║  Total Files Analyzed: ${countPadded}║`)
  let _ = Array.push(
    lines,
    "╚══════════════════════════════════════════════════════════════════════════════╝",
  )
  let _ = Array.push(lines, "")

  let (exifResults, gpsPoints, gpsFilenames, captureDateTime) = await Extraction.extractAllExif(
    sceneDataList,
  )

  let _ = Array.push(
    lines,
    "┌──────────────────────────────────────────────────────────────────────────────┐",
  )
  let _ = Array.push(
    lines,
    "│  📍 LOCATION ANALYSIS                                                        │",
  )
  let _ = Array.push(
    lines,
    "└──────────────────────────────────────────────────────────────────────────────┘",
  )
  let _ = Array.push(lines, "")

  let resolvedAddress = await Location.analyzeLocation(
    gpsPoints,
    gpsFilenames,
    Array.length(sceneDataList),
    lines,
  )

  let _ = Array.push(
    lines,
    "┌──────────────────────────────────────────────────────────────────────────────┐",
  )
  let _ = Array.push(
    lines,
    "│  📷 CAMERA & DEVICE ANALYSIS                                                 │",
  )
  let _ = Array.push(
    lines,
    "└──────────────────────────────────────────────────────────────────────────────┘",
  )
  let _ = Array.push(lines, "")

  Groups.analyzeGroups(exifResults, lines)

  let _ = Array.push(
    lines,
    "┌──────────────────────────────────────────────────────────────────────────────┐",
  )
  let _ = Array.push(
    lines,
    "│  📋 INDIVIDUAL FILE METADATA                                                 │",
  )
  let _ = Array.push(
    lines,
    "└──────────────────────────────────────────────────────────────────────────────┘",
  )
  let _ = Array.push(lines, "")

  Groups.listIndividualFiles(exifResults, lines)

  let _ = Array.push(lines, "")
  let _ = Array.push(lines, String.repeat("═", 80))
  let _ = Array.push(lines, "END OF REPORT")
  let _ = Array.push(lines, String.repeat("═", 80))

  let suggestedName = Utils.generateProjectName(resolvedAddress, captureDateTime)

  Logger.info(
    ~module_="ExifReport",
    ~message="PROJECT_NAME_GENERATED_FROM_EXIF",
    ~data=Some({
      "suggestedName": suggestedName->Option.getOr("None"),
      "hasAddress": resolvedAddress != None,
      "hasDateTime": captureDateTime != None,
      "address": resolvedAddress->Option.getOr("None"),
      "dateTime": captureDateTime->Option.getOr("None"),
    }),
    (),
  )

  {
    report: Array.join(lines, "\n"),
    suggestedProjectName: suggestedName,
  }
}

// Re-expose Utils for backward compatibility if needed, although they were previously included
let downloadExifReport = Utils.downloadExifReport
let generateProjectName = Utils.generateProjectName

// --- COMPATIBILITY ALIASES ---
module ExifReportGeneratorTypes = {
  type sceneDataItem = sceneDataItem
  type exifResult = exifResult
  type reportResult = reportResult
  type localExifResult = localExifResult
  type locationAnalysis = locationAnalysis
}
module ExifReportGeneratorUtils = Utils
