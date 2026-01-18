/* tests/unit/VersionDataTest.res */
open VersionData

let run = () => {
  Console.log("Running VersionDataTest...")

  if version == "" {
    JsError.throwWithMessage("VersionDataTest Failed: version is empty")
  }

  if buildNumber <= 0 {
    JsError.throwWithMessage("VersionDataTest Failed: buildNumber is invalid")
  }

  Console.log("Version: " ++ version)
  Console.log("Build Number: " ++ Int.toString(buildNumber))
  Console.log("✓ VersionData constants verified")

  Console.log("VersionDataTest Passed")
}
