import { notify } from "../utils/NotificationSystem.js";
/**
 * InputSystem.js
 * 
 * Centralized keyboard and mouse event orchestration.
 * Manages global shortcuts like ESC to cancel, ensuring consistent 
 * behavior across modals, navigation, and editing modes.
 */

import { store } from "../store.js";
import { cancelNavigation } from "./NavigationSystem.js";
import { isAutoPilotActive, stopAutoPilot } from "./SimulationSystem.js";
import { Debug } from "../utils/Debug.js";

/**
 * Initialize the global input handlers
 */
export function initInputSystem() {
    Debug.info('InputSystem', 'Initializing Global Input System');

    document.addEventListener('keydown', (e) => {
        // --- GLOBAL ESCAPE HANDLER ---
        if (e.key === 'Escape') {
            handleGlobalEscape(e);
        }
    });

    /**
     * Handle the Escape key press with priority-based cancellation logic.
     */
    function handleGlobalEscape(e) {
        // Priority 1: Sidebar / UI Modals
        // Check for any visible modal boxes
        const modals = [
            'style-modal',
            'new-project-modal',
            'about-modal',
            'modal-container' // LinkModal container
        ];

        for (const modalId of modals) {
            const modal = document.getElementById(modalId);
            if (modal && (modal.style.display === 'flex' || modal.querySelector('.modal-overlay'))) {
                Debug.debug('InputSystem', `Closing modal: ${modalId}`);

                // For LinkModal (in modal-container), it has an internal button
                if (modalId === 'modal-container') {
                    const cancelBtn = modal.querySelector('#cancel-link');
                    if (cancelBtn) {
                        cancelBtn.click();
                        e.preventDefault();
                        return;
                    }
                }

                // For Sidebar Modals (style, new, about)
                const dismissBtn = modal.querySelector('#btn-close-style, #btn-new-cancel, #btn-close-about');
                if (dismissBtn) {
                    dismissBtn.click();
                    e.preventDefault();
                    return;
                }

                // Fallback for custom modals without standard IDs
                const overlay = modal.querySelector('.modal-overlay');
                if (overlay) {
                    // Try to find ANY button that looks like a cancel or close button
                    const anyCancel = modal.querySelector('button[id*="cancel"], button[id*="close"], .btn-secondary');
                    if (anyCancel) {
                        anyCancel.click();
                        e.preventDefault();
                        return;
                    }
                }
            }
        }

        // Priority 2: Context Menus
        const contextMenu = document.getElementById('context-menu');
        if (contextMenu && !contextMenu.classList.contains('hidden')) {
            Debug.debug('InputSystem', 'Hiding Context Menu');
            contextMenu.classList.add('hidden');
            contextMenu.classList.remove('flex');
            e.preventDefault();
            return;
        }

        // Priority 3: Component States (Linking)
        if (store.state.isLinking) {
            Debug.info('InputSystem', 'Cancelling Linking Mode');
            store.setLinkDraft(null);
            store.state.isLinking = false;
            notify("Linking cancelled", "info");
            e.preventDefault();
            return;
        }

        // Priority 4: Simulation Mode (Auto-Pilot)
        if (isAutoPilotActive()) {
            Debug.info('InputSystem', 'Stopping Auto-Pilot via ESC');
            stopAutoPilot(true);
            e.preventDefault();
            return;
        }

        // Priority 5: Active Navigation (Cancel Panning)
        cancelNavigation();
    }
}
