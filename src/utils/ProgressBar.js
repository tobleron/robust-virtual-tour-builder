/**
 * Progress Bar Controller
 * Manages the processing UI progress bar in the sidebar
 * 
 * @module ProgressBar
 */

import { PROGRESS_BAR_AUTO_HIDE_DELAY } from "../constants.js";

// Auto-hide timeout reference
let progressAutoHideTimeout = null;

/**
 * Update the progress bar state
 * @param {number} percent - Progress percentage (0-100)
 * @param {string} text - Status text to display
 * @param {boolean} visible - Whether progress bar should be visible
 * @param {string|null} title - Optional title override
 */
export function updateProgressBar(percent, text, visible = true, title = null) {
    // Clear any existing auto-hide timeout
    if (progressAutoHideTimeout) {
        clearTimeout(progressAutoHideTimeout);
        progressAutoHideTimeout = null;
    }

    // Get DOM elements
    const processingUi = document.getElementById("processing-ui");
    const progressBar = document.getElementById("progress-bar");
    const progressTitle = document.getElementById("progress-title");
    const progressPercentage = document.getElementById("progress-percentage");
    const progressTextContent = document.getElementById("progress-text-content");
    const progressSpinner = document.getElementById("progress-spinner");
    const uploadLabel = document.getElementById("upload-label");

    if (!processingUi || !progressBar) return;

    // Hide progress bar
    if (!visible) {
        processingUi.style.opacity = "0";
        processingUi.style.transform = "translateY(-10px)";
        setTimeout(() => {
            processingUi.style.display = "none";
            processingUi.style.opacity = "1";
            processingUi.style.transform = "translateY(0)";
        }, 300);
        if (uploadLabel) uploadLabel.style.display = "flex";
        return;
    }

    // Show progress bar
    processingUi.style.display = "block";
    processingUi.style.transition = "opacity 0.3s ease, transform 0.3s ease";
    if (uploadLabel) uploadLabel.style.display = "none";

    // Update percentage with clamping
    const clampedPercent = Math.min(100, Math.max(0, percent));
    progressBar.style.width = clampedPercent + "%";
    if (progressPercentage) progressPercentage.textContent = Math.round(clampedPercent) + "%";

    // Update text content
    if (text && progressTextContent) progressTextContent.textContent = text;
    if (title && progressTitle) progressTitle.innerText = title;

    // Show/hide spinner based on completion
    if (progressSpinner) {
        progressSpinner.style.opacity = clampedPercent >= 100 ? "0" : "1";
    }

    // Scroll sidebar to top to show progress
    const sidebarContent = document.querySelector(".sidebar-content");
    if (sidebarContent) sidebarContent.scrollTo({ top: 0, behavior: 'smooth' });

    // Auto-hide on completion
    if (percent >= 100) {
        progressAutoHideTimeout = setTimeout(() => {
            processingUi.style.opacity = "0";
            processingUi.style.transform = "translateY(-10px)";
            setTimeout(() => {
                processingUi.style.display = "none";
                processingUi.style.opacity = "1";
                processingUi.style.transform = "translateY(0)";
                if (uploadLabel) uploadLabel.style.display = "flex";
            }, 300);
            progressAutoHideTimeout = null;
        }, PROGRESS_BAR_AUTO_HIDE_DELAY);
    }
}

/**
 * Initialize progress bar system by attaching to window
 * Should be called once at app startup
 */
export function initProgressBar() {
    window.updateProgressBar = updateProgressBar;
}
