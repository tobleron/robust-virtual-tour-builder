/**
 * GENERATED FILE - DO NOT EDIT MANUALLY
 * This file is updated by scripts/update-version.js
 * It contains both version data and utility functions.
 */
let version = "4.5.4"
let buildNumber = 0
let generatedBuildInfo = "[Development Build]"
let buildInfo = generatedBuildInfo

/**
 * Returns the current application version.
 */
let getVersion = () => version

/**
 * Returns the build information (e.g., "[Stable Release]").
 */
let getBuildInfo = () => buildInfo

/**
 * Returns the generated build information from version sync context.
 */
let getGeneratedBuildInfo = () => generatedBuildInfo

/**
 * Returns a full version string for display.
 */
let getFullVersion = () => `${version} ${buildInfo}`
