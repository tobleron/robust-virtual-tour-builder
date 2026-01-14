/**
 * Version utility for the ReScript frontend.
 * This module provides access to the application version, which is
 * synchronized from package.json by the scripts/update-version.js script.
 */

@module("../version.js") external version: string = "VERSION"
@module("../version.js") external buildInfo: string = "BUILD_INFO"

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
