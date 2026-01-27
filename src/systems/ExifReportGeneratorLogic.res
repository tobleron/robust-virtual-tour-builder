/* src/systems/ExifReportGeneratorLogic.res */

open ReBindings
open SharedTypes
open ExifReportGeneratorTypes
open ExifReportGeneratorUtils
open ExifReportGeneratorLogicExtraction
open ExifReportGeneratorLogicLocation
open ExifReportGeneratorLogicGroups

/**
 * Generate EXIF metadata report from uploaded files
 */
let generateExifReport = async (sceneDataList: array<sceneDataItem>) => {
  Logger.initialized(~module_="ExifReportGeneratorLogic")
  let lines = []

  // Header
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

  // Extraction
  let (exifResults, gpsPoints, gpsFilenames, captureDateTime) = await extractAllExif(sceneDataList)

  // SECTION 1: LOCATION ANALYSIS
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

  let resolvedAddress = await analyzeLocation(
    gpsPoints,
    gpsFilenames,
    Array.length(sceneDataList),
    lines,
  )

  // SECTION 2: CAMERA/DEVICE GROUPING
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

  analyzeGroups(exifResults, lines)

  // SECTION 3: DETAILED FILE LIST
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

  listIndividualFiles(exifResults, lines)

  // Footer
  let _ = Array.push(lines, "")
  let _ = Array.push(lines, String.repeat("═", 80))
  let _ = Array.push(lines, "END OF REPORT")
  let _ = Array.push(lines, String.repeat("═", 80))

  // Generate suggested project name
  let suggestedName = generateProjectName(resolvedAddress, captureDateTime)

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
