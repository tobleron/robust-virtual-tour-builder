/**
 * ColorPalette Utility
 * 
 * Provides consistent coloring for scene clustering across the application.
 */

export const getGroupColor = (groupId) => {
    if (!groupId) return "#f1f5f9"; // Slate 100 (Default)
    const colors = [
        "#3b82f6", // Blue 500
        "#ef4444", // Red 500
        "#10b981", // Emerald 500
        "#f59e0b", // Amber 500
        "#8b5cf6", // Violet 500
        "#ec4899", // Pink 500
        "#06b6d4", // Cyan 500
        "#84cc16", // Lime 500
    ];
    return colors[(groupId - 1) % colors.length];
};
export const darkenColor = (hex, percent) => {
    // Remove # if present
    hex = hex.replace(/^#/, '');

    // Parse R, G, B
    let r = parseInt(hex.substring(0, 2), 16);
    let g = parseInt(hex.substring(2, 4), 16);
    let b = parseInt(hex.substring(4, 6), 16);

    // Darken each channel
    r = Math.floor(r * (1 - percent));
    g = Math.floor(g * (1 - percent));
    b = Math.floor(b * (1 - percent));

    // Ensure they stay in [0, 255]
    r = Math.max(0, Math.min(255, r));
    g = Math.max(0, Math.min(255, g));
    b = Math.max(0, Math.min(255, b));

    // Convert back to hex
    const toHex = (c) => c.toString(16).padStart(2, '0');
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
};
