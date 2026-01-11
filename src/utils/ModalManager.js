/**
 * ModalManager.js
 * 
 * Unified system for managing application modals.
 * Provides a consistent look-and-feel and handles overlay, 
 * animations, and keyboard interactions (ESC to close).
 */

let activeModal = null;

export const ModalManager = {
    /**
     * Show a custom modal
     * @param {Object} options 
     * @param {string} options.title - Modal title
     * @param {string} options.description - Optional subtitle/description
     * @param {string} options.contentHtml - Raw HTML for the modal body
     * @param {Array} options.buttons - Array of button configs { label, onClick, class }
     * @param {string} options.icon - Material icon name
     * @param {boolean} options.allowClose - Show close button/ESC to close (default: true)
     * @param {number} options.maxWidth - Custom max-width (default: 340px)
     */
    show(options) {
        this.close();

        const container = document.getElementById("modal-container");
        if (!container) return;

        const {
            title,
            description = '',
            contentHtml = '',
            buttons = [],
            icon = '',
            iconHtml = '',
            allowClose = true,
            maxWidth = 340,
            onOpen = null
        } = options;

        const modalId = `modal-${Date.now()}`;

        container.innerHTML = `
            <div id="${modalId}" class="modal-overlay" style="display:flex; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); backdrop-filter:blur(12px); z-index:20000; justify-content:center; align-items:center; padding:16px; transition:opacity 0.3s ease-in-out; opacity:0;">
                <div class="modal-box-premium" style="transform:scale(0.95); transition:all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); width: 100%; max-width: ${maxWidth}px;">
                    ${iconHtml ? `
                        <div style="text-align: center; margin-bottom: 16px;">
                            ${iconHtml}
                        </div>
                    ` : (icon ? `
                        <div style="text-align: center; margin-bottom: 16px;">
                            <span class="material-icons" style="font-size: 40px; color: #fbbf24; filter: drop-shadow(0 0 12px rgba(251, 191, 36, 0.4));">${icon}</span>
                        </div>
                    ` : '')}
                    
                    ${title ? `<h3 style="margin: 0 0 4px 0; font-size: 20px; font-weight: 800; letter-spacing: -0.02em; text-align: center; color: white;">${title}</h3>` : ''}
                    
                    ${description ? `<p style="font-size: 13px; color: rgba(255,255,255,0.6); margin-bottom: 20px; text-align: center;">${description}</p>` : ''}
                    
                    <div class="modal-content-body">
                        ${contentHtml}
                    </div>

                    <div class="modal-actions" style="display: flex; flex-direction: column; gap: 10px; margin-top: 20px;">
                        ${buttons.map((btn, i) => `
                            <button id="${modalId}-btn-${i}" class="modal-btn-premium ${btn.class || 'btn-blue'}" style="width: 100%;">
                                <span>${btn.label}</span>
                            </button>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;

        const overlay = document.getElementById(modalId);
        const box = overlay.querySelector('.modal-box-premium');

        // Trigger animations
        requestAnimationFrame(() => {
            overlay.style.opacity = '1';
            box.style.transform = 'scale(1)';
        });

        // Attach button listeners
        buttons.forEach((btn, i) => {
            const btnEl = document.getElementById(`${modalId}-btn-${i}`);
            if (btnEl) {
                btnEl.onclick = () => {
                    if (btn.onClick) btn.onClick();
                    if (btn.autoClose !== false) this.close();
                };
            }
        });

        activeModal = { id: modalId, allowClose, onClose: options.onClose };

        if (onOpen) onOpen(overlay);

        // Escape key handler
        if (allowClose) {
            const escHandler = (e) => {
                if (e.key === 'Escape') {
                    this.close();
                    document.removeEventListener('keydown', escHandler);
                }
            };
            document.addEventListener('keydown', escHandler);
        }
    },

    /**
     * Show a simple confirmation modal
     */
    confirm(options) {
        this.show({
            ...options,
            buttons: [
                { label: options.confirmLabel || 'Confirm', onClick: options.onConfirm, class: options.confirmClass || 'btn-green' },
                { label: options.cancelLabel || 'Cancel', onClick: options.onCancel, class: 'btn-secondary' }
            ]
        });
    },

    /**
     * Close the currently active modal
     */
    close() {
        if (!activeModal) return;

        const { id, onClose } = activeModal;
        const overlay = document.getElementById(id);
        if (overlay) {
            const box = overlay.querySelector('.modal-box-premium');
            overlay.style.opacity = '0';
            if (box) box.style.transform = 'scale(0.95)';

            setTimeout(() => {
                overlay.remove();
                if (onClose) onClose();
            }, 300);
        }

        activeModal = null;
    }
};
