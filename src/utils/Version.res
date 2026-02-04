/**
 * GENERATED FILE - DO NOT EDIT MANUALLY
 * This file is updated by scripts/update-version.js
 * It contains both version data and utility functions.
 */
let version = "4.15.0"
let buildNumber = 2
let buildInfo = "[Development Build]"

/**
 * Returns the current application version.
 */
let getVersion = () => version

/**
 * Returns the build information (e.g., "[Stable Release]").
 */
let getBuildInfo = () => buildInfo

/**
 * Returns a full version string for display.
 */
let getFullVersion = () => `${version} ${buildInfo}`
