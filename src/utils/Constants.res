/**
 * Application-wide constants
 * Centralizing magic numbers for better maintainability
 */
let // ============================================
// DEBUG CONFIGURATION
// ============================================

debugEnabledDefault = false
let debugLogLevel = "info"
let debugMaxEntries = 500
let perfWarnThreshold = 500.0 // ms
let perfInfoThreshold = 100.0 // ms

// ============================================
// HOTSPOT CONFIGURATION
// ============================================

let hotspotVisualOffsetDegrees = 0.0
let returnLinkDefaultPitch = 0.0
let returnLinkDisplayOffset = -15.0
let linkingRodHeight = 80.0
let hotspotMenuOpenDelay = 900
let hotspotMenuExitDelay = 600

// ============================================
// VIEWER CONFIGURATION
// ============================================

let globalHfov = 90.0
let globalMinHfov = 65.0
let globalMaxHfov = 90.0
let builderLandscapeMinWidth = 640.0
let builderLandscapeMaxWidth = 1024.0

// ============================================
// TEASER SYSTEM CONFIGURATION
// ============================================

module Teaser = {
  let canvasWidth = 1920
  let canvasHeight = 1080
  let frameRate = 60
  module HeadlessMotion = {
    // Keep teaser deterministic with simulation math while skipping intro-pan capture.
    let skipAutoForward = false
    let startAtWaypoint = true
    let includeIntroPan = false
  }

  module StyleDissolve = {
    let clipDuration = 2000
    let transitionDuration = 1000
    let cameraPanOffset = 8.0
  }

  module StylePunchy = {
    let clipDuration = 1200
    let transitionDuration = 200
    let cameraPanOffset = 0.0
  }

  module Logo = {
    let width = 150
    let padding = 30
    let borderRadius = 12
  }

  module Processing = {
    let preflightSampleFrames = 5
    let progressSmoothingAlpha = 0.2
  }
}

let webpQuality = 0.92

// ============================================
// IMAGE PROCESSING
// ============================================

let processedImageWidth = 4096
let imageResizeQuality = "high"

// ============================================
// PROGRESS BAR
// ============================================

let progressBarAutoHideDelay = 2400

// ============================================
// NOTIFICATION SYSTEM
// ============================================

let toastDisplayDuration = 4000
let toastAnimationDuration = 1000 // ms - synced with CSS 1.0s transition
let toastVisibleToasts = 3
let toastStackGap = 5 // px

// ============================================
// DOWNLOAD SYSTEM
// ============================================

let blobUrlCleanupDelay = 60000

// ============================================
// FFMPEG CONFIGURATION
// ============================================

module FFmpeg = {
  let crfQuality = 18
  let preset = "medium"
  let coreVersion = "0.12.10"
}

// ============================================
// PROJECT MANAGEMENT
// ============================================

let zipCompressionLevel = 6
let uiYieldDelay = 10

// ============================================
// ANIMATION TIMING
// ============================================

let modalFadeDuration = 100
let panningVelocity = 25.0 // Degrees per second - Slower for majesty
let panningMinDuration = 1000.0 // 1.0s - Minimum time to allow perceptible acceleration/deceleration
let panningMaxDuration = 20000.0 // 20s - Allow very long slow journeys
let sceneStabilizationDelay = 1000
let viewerLoadCheckInterval = 100
let tooltipDelayDuration = 2400

// ============================================
// SCENE ORGANIZATION
// ============================================

module Scene = {
  module Categories = {
    let indoor = "indoor"
    let outdoor = "outdoor"
  }

  type floorLevel = {
    id: string,
    label: string,
    short: string,
    suffix?: string,
  }

  let floorLevels: array<floorLevel> = [
    {id: "b2", label: "Basement 2", short: "B", suffix: "-2"},
    {id: "b1", label: "Basement 1", short: "B", suffix: "-1"},
    {id: "ground", label: "Ground Floor", short: "G"},
    {id: "first", label: "First Floor", short: "+1"},
    {id: "second", label: "Second Floor", short: "+2"},
    {id: "third", label: "Third Floor", short: "+3"},
    {id: "fourth", label: "Fourth Floor", short: "+4"},
    {id: "roof", label: "Roof Top", short: "R"},
  ]

  module Defaults = {
    let category = "outdoor"
    let floor = "ground"
    let label = ""
    let description = ""
  }

  module RoomLabels = {
    let outdoor = [
      "Zoom Out View",
      "Street View",
      "Entrance",
      "Front Yard",
      "Backyard",
      "Right Side",
      "Left Side",
      "Garden",
      "Pool Area",
      "Gazebo",
      "BBQ Area",
      "Terrace",
      "Driver's Room",
      "Garage",
      "Carport",
    ]

    let indoor = [
      "Entrance Hall",
      "Majlis",
      "Family Living",
      "Formal Living",
      "Dining Room",
      "Kitchen",
      "Dirty Kitchen",
      "Pantry",
      "Hallway",
      "Staircase",
      "Elevator Lobby",
      "Master Bedroom",
      "Bedroom",
      "Guest Room",
      "Bathroom",
      "Powder Room",
      "Office",
      "Study",
      "Home Cinema",
      "Gym",
      "Maid's Room",
      "Laundry Room",
      "Storage",
      "Balcony",
      "Roof",
    ]
  }
}

let roomLabelPresets = Dict.fromArray([
  ("outdoor", Scene.RoomLabels.outdoor),
  ("indoor", Scene.RoomLabels.indoor),
])

// ============================================
// BACKEND CONFIGURATION
// ============================================

// Helper to safely get environment variables across Vite and Node
let getEnv = (name: string, fallback: string): string => {
  ignore(name)
  let value = try {
    %raw(`(typeof import.meta !== 'undefined' && import.meta.env ? import.meta.env[name] : (typeof process !== 'undefined' && process.env ? process.env[name] : null))`)
  } catch {
  | _ => Nullable.null
  }
  value->Nullable.toOption->Option.getOr(fallback)
}

let backendUrl = getEnv("VITE_BACKEND_URL", "http://localhost:8080")

// ============================================
// NAVIGATION & SIMULATION
// ============================================

let blinkDurationPreview = 1200
let blinkDurationSimulation = 1200
let blinkRatePreview = 300
let blinkRateSimulation = 600
let idleSnapshotDelay = 2000
let waypointSmoothingFactor = 0.3 // 0.0 (raw) to 1.0 (max smoothing)

module Simulation = {
  let stepDelay = 5000
}
let isTestEnvironment = () => {
  try {
    %raw(`(typeof process !== 'undefined' && (process.env.NODE_ENV === 'test' || process.env.VITEST === 'true'))`)
  } catch {
  | _ => false
  }
}

module Exporter = {
  let retryDelayMs = if isTestEnvironment() {
    0
  } else {
    2000
  }
  // Backend export endpoint allows up to 10 minutes; keep client timeout above that
  // to avoid abort+retry loops on large packages (e.g. x700-class projects).
  let uploadTimeoutMs = if isTestEnvironment() {
    30000
  } else {
    720000
  }
}

module Media = {
  // Frontend pre-upload compression quality for WebP conversion (0.0 - 1.0)
  let uploadWebpQuality = 0.92
  // Export scene normalization policy
  let exportSceneWebpQuality = 0.92
  let exportSceneMaxWidth = Float.fromInt(processedImageWidth)
  let exportScenePolicy = "browser-webp92-v1"
  // Branding/logo normalization policy
  let logoWebpQuality = 0.92
  let logoMaxWidth = 1024.0
  let logoMaxHeight = 1024.0
  let logoOutputFilename = "logo.webp"
}
let sceneLoadTimeout = 30000

// ============================================
// TELEMETRY CONFIGURATION
// ============================================

module Telemetry = {
  // --- CONFIGURATION ---
  // Allow the env to override diagnostics while keeping production off by default
  let mode = getEnv("MODE", "production")
  let isDevStr = getEnv("DEV", "false")
  let debugBuild = mode == "development" || isDevStr == "true"
  let diagnosticEnvOverride = getEnv("VITE_TELEMETRY_DIAGNOSTIC", "false") == "true"
  let startInDiagnosticMode = debugBuild || diagnosticEnvOverride

  let enabled = getEnv("VITE_TELEMETRY_ENABLED", "true") == "true"

  // Micro-management: Add keys here to allow Trace/Debug logs for specific modules only
  // If array is empty ["*"] or diagnosticMode is true, ALL logs are sent.
  // Example: ["Teaser", "Navigation"]
  let traceFilterModules: array<string> = []

  // --- INTERNAL ---
  let batchInterval = 5000 // ms
  let batchSize = 50 // max entries per batch
  let queueMaxSize = 1000 // total buffered logs
  let retryMaxAttempts = 3
  let retryBackoffMs = 1000
  let diagnosticMode = ref(startInDiagnosticMode)
  let suspendDurationMs = 30000.0

  // --- BACKPRESSURE CONFIG ---
  let transportMaxConcurrent = 2
  let transportMaxQueued = 32
  let lowPrioritySamplingThreshold = 0.75
  let lowPriorityDropThreshold = 0.95
  let lowPrioritySamplingRate = 0.35

  // Keys that should be stripped from telemetry payloads
  let sensitiveFields: array<string> = [
    "password",
    "pwd",
    "token",
    "authToken",
    "authorization",
    "apiKey",
    "api_key",
    "accessToken",
    "refreshToken",
    "sessionToken",
    "secret",
    "credentials",
    "privateKey",
    "ssn",
  ]
}

// ============================================
// SYSTEM UTILITIES
// ============================================

let isDebugBuild = () => {
  let mode = getEnv("MODE", "production")
  let isDevStr = getEnv("DEV", "false")
  mode == "development" || isDevStr == "true"
}

let enableStateInspector = () => {
  try {
    %raw(`typeof process !== 'undefined' && process.env.ENABLE_STATE_INSPECTOR === 'true'`) ||
    isDebugBuild()
  } catch {
  | _ => isDebugBuild()
  }
}
