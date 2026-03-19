/**
 * GENERATED FILE - DO NOT EDIT MANUALLY
 * This file is updated by scripts/update-version.js
 * It contains both version data and utility functions.
 */

let version = "5.3.6"
let buildNumber = 59
let generatedBuildInfo = "[Development Build]"
let buildInfo = "[Development Build 59]"

/**
 * Returns the current application version.
 */
let getVersion = () => version

/**
 * Returns the build number for the current build.
 */
let getBuildNumber = () => buildNumber

/**
 * Returns the build information (e.g., "[Stable Release]").
 */
let getBuildInfo = () => buildInfo

/**
 * Returns the generated build information from version sync context.
 */
let getGeneratedBuildInfo = () => generatedBuildInfo

/**
 * Returns a full version string for display (version + build).
 */
let getFullVersion = () => `${version}+${Belt.Int.toString(buildNumber)}`

/**
 * Returns the version label with the `v` prefix (e.g., "v1.2.3").
 */
let getVersionLabel = () => `v${version}`
