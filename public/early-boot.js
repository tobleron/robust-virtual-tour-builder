/**
 * EMERGENCY TELEMETRY
 * Catch errors that happen BEFORE main application modules load.
 */
const logEmergency = (level, message, data) => {
  fetch('http://localhost:8080/log-telemetry', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      level: level,
      module: 'EarlyBoot',
      message: message,
      data: data,
      timestamp: new Date().toISOString()
    })
  }).catch(() => { }); // Silent fail
};

window.onerror = (message, source, lineno, colno, error) => {
  console.error("[EarlyBoot] Uncaught Error:", message);
  logEmergency('error', `Early Uncaught Error: ${message}`, {
    source, lineno, colno,
    stack: error?.stack,
    type: error?.name || 'Error'
  });
};

window.onunhandledrejection = (event) => {
  const reason = event.reason;
  console.error("[EarlyBoot] Unhandled Rejection:", reason);
  logEmergency('error', "Early Unhandled Promise Rejection", {
    reason: reason instanceof Error ? reason.message : reason,
    stack: reason instanceof Error ? reason.stack : null
  });
};

// Force WebGL to keep the image buffer available for recording
const oldGetContext = HTMLCanvasElement.prototype.getContext;
HTMLCanvasElement.prototype.getContext = function (type, attributes) {
  if (
    type === "webgl" ||
    type === "experimental-webgl" ||
    type === "webgl2"
  ) {
    attributes = attributes || {};
    attributes.preserveDrawingBuffer = true; // <--- The Magic Switch
    attributes.alpha = false; // Force opaque background
  }
  return oldGetContext.call(this, type, attributes);
};
