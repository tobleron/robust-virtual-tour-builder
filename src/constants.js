/**
 * Application-wide constants
 * Centralizing magic numbers for better maintainability
 */

// ============================================
// DEBUG CONFIGURATION
// ============================================

/**
 * Debug mode enabled by default (should be false for production)
 */
export const DEBUG_ENABLED_DEFAULT = false;

/**
 * Minimum log level to display: 'debug' | 'info' | 'warn' | 'error'
 * Standard Baseline:
 * - 'debug': Intensive development (timing, math, frames)
 * - 'info': Architectural events (batch starts, transitions)
 * - 'warn/error': Critical failures
 */
export const DEBUG_LOG_LEVEL = 'info';

/**
 * Maximum number of debug entries to keep in buffer
 */
export const DEBUG_MAX_ENTRIES = 500;

// ============================================
// HOTSPOT CONFIGURATION
// ============================================

/**
 * Visual offset for hotspot arrow placement (degrees below actual click point)
 * This creates a "floor-level" appearance for navigation arrows
 */
export const HOTSPOT_VISUAL_OFFSET_DEGREES = 15;

/**
 * Default pitch for return links (straight ahead)
 */
export const RETURN_LINK_DEFAULT_PITCH = 0;

/**
 * Display pitch offset for return links
 */
export const RETURN_LINK_DISPLAY_OFFSET = -15;

// ============================================
// VIEWER CONFIGURATION
// ============================================

/**
 * Global horizontal field of view for optimal image sharpness
 * 90° provides good balance between immersion and distortion
 */
export const GLOBAL_HFOV = 90;

// ============================================
// TEASER SYSTEM CONFIGURATION
// ============================================

/**
 * Canvas resolution for teaser recording (Full HD)
 */
export const TEASER_CANVAS_WIDTH = 1920;
export const TEASER_CANVAS_HEIGHT = 1080;

/**
 * Teaser recording frame rate (FPS)
 * 24 FPS is cinematic standard and reduces file size
 */
export const TEASER_FRAME_RATE = 60;

/**
 * Teaser style: Dissolve (smooth crossfade between scenes)
 */
export const TEASER_STYLE_DISSOLVE = {
  /** Duration each scene is visible (milliseconds) */
  clipDuration: 2000,
  /** Crossfade transition duration (milliseconds) */
  transitionDuration: 1000,
  /** Camera pan offset (degrees) - creates subtle "glance" motion */
  cameraPanOffset: 8,
};

/**
 * Teaser style: Punchy (quick hard cuts, no transitions)
 */
export const TEASER_STYLE_PUNCHY = {
  /** Duration each scene is visible (milliseconds) */
  clipDuration: 1200,
  /** Brief pause between cuts (milliseconds) */
  transitionDuration: 200,
  /** No camera pan for punchy style */
  cameraPanOffset: 0,
};

/**
 * Logo watermark configuration
 */
export const TEASER_LOGO = {
  /** Logo width in pixels (16:9 aspect maintained) */
  width: 150,
  /** Padding from bottom-right corner */
  padding: 30,
  /** Border radius for rounded corners */
  borderRadius: 12,
};

/**
 * WebP compression quality (0.0 - 1.0)
 * 0.92 is visually lossless while saving ~40% file size
 */
export const WEBP_QUALITY = 0.92;

// ============================================
// IMAGE PROCESSING
// ============================================

/**
 * Target width for processed images (4K resolution)
 * 4096px is the sweet spot for 7-inch tablets and web viewing
 */
export const PROCESSED_IMAGE_WIDTH = 4096;

/**
 * Image processing quality setting
 */
export const IMAGE_RESIZE_QUALITY = "high";

// ============================================
// PROGRESS BAR
// ============================================

/**
 * Auto-hide delay for progress bar after completion (milliseconds)
 */
export const PROGRESS_BAR_AUTO_HIDE_DELAY = 2400;

// ============================================
// NOTIFICATION SYSTEM
// ============================================

/**
 * Toast notification display duration (milliseconds)
 */
export const TOAST_DISPLAY_DURATION = 4000;

/**
 * Toast animation duration (milliseconds)
 */
export const TOAST_ANIMATION_DURATION = 400;

// ============================================
// DOWNLOAD SYSTEM
// ============================================

/**
 * Delay before cleaning up blob URLs (milliseconds)
 * 60 seconds ensures download completes on slow connections
 */
export const BLOB_URL_CLEANUP_DELAY = 60000;

// ============================================
// FFMPEG CONFIGURATION
// ============================================

/**
 * FFmpeg video encoding quality (CRF scale)
 * 18 = visually near-lossless (lower = better quality, larger file)
 * Range: 0 (lossless) to 51 (worst quality)
 */
export const FFMPEG_CRF_QUALITY = 18;

/**
 * FFmpeg encoding preset
 * Options: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
 * 'medium' provides good balance of speed and compression
 */
export const FFMPEG_PRESET = "medium";

/**
 * FFmpeg core library version for caching
 */
export const FFMPEG_CORE_VERSION = "0.12.10";

// ============================================
// PROJECT MANAGEMENT
// ============================================

/**
 * ZIP compression level (0-9)
 * 6 = balanced compression and speed
 */
export const ZIP_COMPRESSION_LEVEL = 6;

/**
 * UI breathing delay during batch operations (milliseconds)
 * Prevents UI freezing during intensive loops
 */
export const UI_YIELD_DELAY = 10;

// ============================================
// ANIMATION TIMING
// ============================================

/**
 * Modal fade-in duration (milliseconds)
 */
export const MODAL_FADE_DURATION = 100;

/**
 * Panning Velocity (Degrees per second)
 * Lower is slower. 35-45 is calm and cinematic.
 */
export const PANNING_VELOCITY = 9;

/**
 * Minimum and Maximum durations for panning animations (milliseconds)
 * Prevents motions from being either too fast (jarring) or too slow (boring).
 */
export const PANNING_MIN_DURATION = 1500;
export const PANNING_MAX_DURATION = 6000;

/**
 * Scene stabilization delay after load (milliseconds)
 */
export const SCENE_STABILIZATION_DELAY = 1000;

/**
 * Viewer load check interval (milliseconds)
 */
export const VIEWER_LOAD_CHECK_INTERVAL = 100;

// ============================================
// SCENE ORGANIZATION
// ============================================

/**
 * Scene category options
 */
export const SCENE_CATEGORIES = {
  INDOOR: "indoor",
  OUTDOOR: "outdoor",
};

/**
 * Floor level options (ordered for UI display)
 */
export const FLOOR_LEVELS = [
  { id: "b2", label: "Basement 2", short: "B", suffix: "-2" },
  { id: "b1", label: "Basement 1", short: "B", suffix: "-1" },
  { id: "ground", label: "Ground Floor", short: "G" },
  { id: "first", label: "First Floor", short: "+1" },
  { id: "second", label: "Second Floor", short: "+2" },
  { id: "third", label: "Third Floor", short: "+3" },
  { id: "fourth", label: "Fourth Floor", short: "+4" },
  { id: "roof", label: "Roof Top", short: "R" },
];

/**
 * Default values for new scenes
 */
export const SCENE_DEFAULTS = {
  category: "indoor",
  floor: "ground",
  label: "",
  description: "",
};

/**
 * Common room label presets for quick selection, categorized by area
 */
export const ROOM_LABEL_PRESETS = {
  outdoor: [
    "Zoom Out View", "Street View", "Entrance", "Front Yard", "Backyard",
    "Right Side", "Left Side", "Garden", "Pool Area", "Gazebo",
    "BBQ Area", "Terrace", "Driver's Room", "Garage", "Carport"
  ],
  indoor: [
    "Entrance Hall", "Majlis", "Family Living", "Formal Living", "Dining Room",
    "Kitchen", "Dirty Kitchen", "Pantry", "Hallway", "Staircase",
    "Elevator Lobby", "Master Bedroom", "Bedroom", "Guest Room",
    "Bathroom", "Powder Room", "Office", "Study", "Home Cinema",
    "Gym", "Maid's Room", "Laundry Room", "Storage", "Balcony", "Roof"
  ]
};

// ============================================
// BACKEND CONFIGURATION
// ============================================

/**
 * URL of the Rust backend server
 */
export const BACKEND_URL = "http://localhost:8080";

// ============================================
// NAVIGATION & SIMULATION
// ============================================

/**
 * Blink duration for preview mode (milliseconds)
 */
export const BLINK_DURATION_PREVIEW = 1200;

/**
 * Blink duration for simulation mode (milliseconds)
 */
export const BLINK_DURATION_SIMULATION = 600;

/**
 * Rate of blinking for preview mode (milliseconds per state)
 */
export const BLINK_RATE_PREVIEW = 300;

/**
 * Rate of blinking for simulation mode (milliseconds per state)
 */
export const BLINK_RATE_SIMULATION = 150;

/**
 * Timeout for idle snapshot capture (milliseconds)
 */
export const IDLE_SNAPSHOT_DELAY = 2000;

/**
 * Safety timeout for scene loading (milliseconds)
 */
export const SCENE_LOAD_TIMEOUT = 10000;
