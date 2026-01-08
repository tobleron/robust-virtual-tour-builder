/**
 * AudioManager System
 * Handles playbacks of UI sounds (ASMR Ticks/Clicks)
 */

class AudioManager {
    constructor() {
        this.clickSoundUrl = "sounds/click.wav";
        this.audioContext = null;
        this.clickBuffer = null;
        this.isInitialized = false;

        // Pre-create audio element for fallback
        this.clickAudio = new Audio(this.clickSoundUrl);
        this.clickAudio.volume = 0.4; // Soft ASMR volume
    }

    /**
     * Initialize on first user interaction (browser requirement)
     */
    init() {
        if (this.isInitialized) return;

        // We can also use Web Audio API for faster response
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        this.isInitialized = true;

        // Optional: Pre-fetch buffer for zero-latency
        fetch(this.clickSoundUrl)
            .then(res => res.arrayBuffer())
            .then(data => this.audioContext.decodeAudioData(data))
            .then(buffer => {
                this.clickBuffer = buffer;
            })
            .catch(e => console.warn("AudioBuffer load failed, using <img> fallback", e));
    }

    /**
     * Play the calming tick sound
     */
    playTick() {
        if (!this.isInitialized) {
            // Try simple audio play if context not ready
            this.clickAudio.currentTime = 0;
            this.clickAudio.play().catch(() => { });
            return;
        }

        if (this.clickBuffer && this.audioContext) {
            if (this.audioContext.state === 'suspended') {
                this.audioContext.resume();
            }
            const source = this.audioContext.createBufferSource();
            source.buffer = this.clickBuffer;
            const gainNode = this.audioContext.createGain();
            gainNode.gain.value = 0.4;
            source.connect(gainNode);
            gainNode.connect(this.audioContext.destination);
            source.start(0);
        } else {
            // Fallback
            this.clickAudio.currentTime = 0;
            this.clickAudio.play().catch(() => { });
        }
    }
}

export const audioManager = new AudioManager();

/**
 * Global helper to attach sounds to UI elements
 */
export function setupGlobalClickSounds() {
    document.addEventListener("mousedown", (e) => {
        const target = e.target.closest("button, .floor-circle, .label-menu-item, .header-menu-btn");
        if (target) {
            audioManager.init(); // Initialize on first click
            audioManager.playTick();
        }
    }, true);
}
