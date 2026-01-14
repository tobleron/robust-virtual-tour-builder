# Report: Add Debug Keyboard Shortcut and DevTools Integration

## Objective (Completed)
Add a keyboard shortcut (Ctrl+Shift+D) for toggling debug mode and improve the developer tools experience.

## Context
During development and troubleshooting, quickly toggling debug mode is essential. A keyboard shortcut makes this faster than opening the console.

## Prerequisites
- Logger.res module exists ✅
- Debug.js updated ✅

## Implementation Details

### 1. Add Keyboard Shortcut to InputSystem.res

```rescript
let handleKeyDown = (event: Dom.keyboardEvent): unit => {
  // Existing ESC handling...
  
  // Debug toggle: Ctrl+Shift+D
  if event.ctrlKey && event.shiftKey && event.key == "D" {
    event.preventDefault()
    let isNowEnabled = DebugJS.toggle()
    Logger.info(~module_="InputSystem", ~message="DEBUG_TOGGLE", ~data=Some({
      "enabled": isNowEnabled
    }), ())
    Notification.notify(
      isNowEnabled ? "Debug mode enabled" : "Debug mode disabled",
      "info"
    )
  }
}
```

### 2. Add DebugJS Binding

In `ReBindings.res` or `Logger.res`:

```rescript
module DebugJS = {
  // ... existing bindings
  
  @module("./utils/Debug.js") @val @scope("Debug")
  external toggle: unit => bool = "toggle"
}
```

### 3. Add Visual Indicator (Optional)

When debug mode is on, show a subtle indicator:

```javascript
// In Debug.js enable()
enable() {
    this.enabled = true;
    this.showDebugBadge();
    // ...
}

showDebugBadge() {
    if (document.getElementById('debug-badge')) return;
    const badge = document.createElement('div');
    badge.id = 'debug-badge';
    badge.textContent = '🐛 DEBUG';
    badge.style.cssText = `
        position: fixed;
        bottom: 10px;
        right: 10px;
        background: #1e293b;
        color: #10b981;
        padding: 4px 8px;
        border-radius: 4px;
        font-family: monospace;
        font-size: 12px;
        z-index: 9999;
        pointer-events: none;
    `;
    document.body.appendChild(badge);
}

hideDebugBadge() {
    document.getElementById('debug-badge')?.remove();
}
```

### 4. Add Quick Level Change Shortcuts (Optional)

```rescript
// Ctrl+Shift+1 = trace, Ctrl+Shift+2 = debug, etc.
if event.ctrlKey && event.shiftKey {
  switch event.key {
  | "1" => {
      Logger.setLevel(Trace)
      Notification.notify("Log level: trace", "info")
    }
  | "2" => {
      Logger.setLevel(Debug)
      Notification.notify("Log level: debug", "info")
    }
  | "3" => {
      Logger.setLevel(Info)
      Notification.notify("Log level: info", "info")
    }
  | _ => ()
  }
}
```

### 5. Document Shortcuts

Add to README or help modal:

| Shortcut | Action |
|----------|--------|
| Ctrl+Shift+D | Toggle debug mode |
| Ctrl+Shift+1 | Set log level to trace |
| Ctrl+Shift+2 | Set log level to debug |
| Ctrl+Shift+3 | Set log level to info |

## Files to Modify

| File | Changes |
|------|---------|
| `src/systems/InputSystem.res` | Add keyboard shortcut handling |
| `src/ReBindings.res` | Add toggle binding |
| `src/utils/Debug.js` | Add visual badge (optional) |

## Testing Checklist

- [ ] Ctrl+Shift+D toggles debug mode
- [ ] Notification confirms mode change
- [ ] Visual badge appears when debug is on
- [ ] Level shortcuts work
- [ ] Shortcuts don't interfere with browser defaults

## Definition of Done

- Debug toggle shortcut implemented
- Notification confirms state change
- Documented in help/README
