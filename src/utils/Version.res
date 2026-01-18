/**
 * Version utility for the ReScript frontend.
 * This module provides access to the application version, which is
 * synchronized from package.json by the scripts/update-version.js script.
 */
/**
 * Returns the current application version.
 */
let getVersion = () => VersionData.version

/**
 * Returns the build information (e.g., "[Stable Release]").
 */
let getBuildInfo = () => VersionData.buildInfo

/**
 * Returns a full version string for display.
 */
let getFullVersion = () => `${VersionData.version} ${VersionData.buildInfo}`
