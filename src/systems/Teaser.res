/* src/systems/Teaser.res - Consolidated Teaser System */

include TeaserLogic

// --- FACADE (TOP LEVEL) ---

let startAutoTeaser = Manager.startAutoTeaser
let startCinematicTeaser = Manager.startCinematicTeaser
let startHeadlessTeaser = Manager.startHeadlessTeaser

// --- COMPATIBILITY ALIASES ---
module TeaserRecorder = Recorder
module TeaserManager = Manager
module TeaserState = State
module TeaserPlayback = Playback
module TeaserPathfinder = Pathfinder
