/**
 * NamingUtils.js
 * 
 * Pure utility functions for sanitizing names and generating unique identifiers.
 * Free of side effects and store dependencies.
 */

/**
 * Sanitize scene/tour names to prevent filesystem issues and ensure cross-platform compatibility
 * @param {string} name - Raw name input
 * @param {number} maxLength - Maximum allowed length (default: 255)
 * @returns {string} Sanitized name
 */
export function sanitizeName(name, maxLength = 255) {
    if (!name || typeof name !== 'string') {
        return 'Untitled';
    }

    return name
        .trim()
        // Remove control characters and invalid filesystem characters
        .replace(/[\x00-\x1F\x7F<>:"\/\\|?*]/g, '_')
        // Replace multiple spaces/underscores with single underscore
        .replace(/[_\s]+/g, '_')
        // Remove leading/trailing underscores
        .replace(/^_+|_+$/g, '')
        // Limit length
        .substring(0, maxLength)
        // Fallback if empty after sanitization
        || 'Untitled';
}

/**
 * Generate a concise, unique Link ID (e.g., A01, B99)
 * Format: [Letter][Digit][Digit]
 * Capacity: 2600 unique IDs (should be sufficient for any single tour)
 * @param {Set<string>} usedIds - Set of already taken IDs
 * @returns {string} A unique ID
 */
export function generateLinkId(usedIds) {
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    // Try to find the first unused ID sequentially
    for (let l = 0; l < letters.length; l++) {
        const char = letters[l];
        for (let n = 0; n < 100; n++) {
            const num = n.toString().padStart(2, '0');
            const candidate = `${char}${num}`;
            if (!usedIds.has(candidate)) {
                return candidate;
            }
        }
    }

    // Fallback (extremely unlikely in normal usage)
    return `Z${Math.floor(Math.random() * 99).toString().padStart(2, '0')}`;
}

/**
 * Calculate the standardized filename for a scene based on its index and label.
 * @param {number} index - 0-based index of the scene
 * @param {string} label - User-provided label
 * @returns {string} The computed filename (e.g., "01_living_room.webp")
 */
export function computeSceneFilename(index, label) {
    const prefix = (index + 1).toString().padStart(2, '0');
    if (!label) return `${prefix}_unnamed.webp`;

    const sanitizedLabel = sanitizeName(label, 200);
    const baseSlug = sanitizedLabel
        .replace(/[\s-]+/g, "_")
        .replace(/[^a-z0-9_]/gi, "")
        .toLowerCase();

    return `${prefix}_${baseSlug}.webp`;
}

/**
 * Perform a structural integrity check on a tour state.
 * Identifies orphaned links (links targeting non-existent scenes).
 * @param {Object} state - The tour state to validate
 * @returns {Object} { totalHotspots, orphanedLinks, details: [] }
 */
export function validateTourIntegrity(state) {
    const sceneNames = new Set(state.scenes.map(s => s.name));
    let totalHotspots = 0;
    let orphanedLinks = 0;
    const details = [];

    state.scenes.forEach(scene => {
        scene.hotspots.forEach(hs => {
            totalHotspots++;
            if (!sceneNames.has(hs.target)) {
                orphanedLinks++;
                details.push({
                    sourceScene: scene.name,
                    targetMissing: hs.target
                });
            }
        });
    });

    return { totalHotspots, orphanedLinks, details };
}
