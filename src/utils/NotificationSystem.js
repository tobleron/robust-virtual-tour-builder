/**
 * Notification System
 * Provides toast notifications as a replacement for native alerts
 * 
 * @module NotificationSystem
 */

import { TOAST_DISPLAY_DURATION, TOAST_ANIMATION_DURATION } from "../constants.js";
import { Debug } from "./Debug.js";

/**
 * Show a toast notification
 * @param {string} message - Message to display
 * @param {string} type - Notification type: "info", "success", "warning", "error"
 */
export function notify(message, type = "info") {
    // Log for telemetry
    if (type === 'error') {
        Debug.error("UI", `Notification: ${message}`);
    } else {
        Debug.info("UI", `Notification: ${message}`);
    }

    const notificationContainer = document.getElementById("notification-container");
    if (!notificationContainer) return;

    const toast = document.createElement("div");
    toast.className = `toast ${type}`;

    // Select icon based on type
    let icon = "ℹ️";
    if (type === "error") icon = "❌";
    if (type === "success") icon = "✅";
    if (type === "warning") icon = "⚠️";

    const iconSpan = document.createElement("span");
    iconSpan.textContent = icon;

    const messageSpan = document.createElement("span");
    messageSpan.textContent = message;

    toast.appendChild(iconSpan);
    toast.appendChild(messageSpan);
    notificationContainer.appendChild(toast);

    // Trigger entrance animation
    requestAnimationFrame(() => toast.classList.add("show"));

    // Auto-dismiss after duration
    setTimeout(() => {
        toast.classList.remove("show");
        setTimeout(() => toast.remove(), TOAST_ANIMATION_DURATION);
    }, TOAST_DISPLAY_DURATION);
}
