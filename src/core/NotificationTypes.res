// src/core/NotificationTypes.res
// Type-safe foundation for the unified notification system
// Defines all notification contracts and helper functions

// Importance levels for notification priority (used for sorting and timeout)
type importance =
  | Critical // Persist until dismissed, highest priority
  | Error // 8 second timeout, high priority
  | Warning // 5 second timeout, medium priority
  | Success // 3 second timeout, medium-low priority
  | Info // 3 second timeout, low priority
  | Transient // 2 second timeout, lowest priority (quick flash)

// Context captures what operation/action triggered the notification
type context =
  | Operation(string) // "upload", "export", "project_load", etc.
  | UserAction(string) // "delete", "save", "navigate", etc.
  | SystemEvent(string) // "timeout", "recovery", "connection_lost", etc.

// Action represents an interactive button in a notification
type action = {
  label: string, // Button text ("Retry", "Dismiss", etc.)
  onClick: unit => unit, // Callback when button clicked
  shortcut: option<string>, // Optional keyboard shortcut (e.g., "u")
}

// Complete notification record - all data needed to display and manage a notification
type notification = {
  id: string, // Unique ID: "notif-{timestamp}-{random}"
  importance: importance, // Priority for sorting
  context: context, // What triggered this
  message: string, // Main notification text
  details: option<string>, // Optional additional details
  action: option<action>, // Optional interactive button
  duration: int, // Auto-dismiss timeout in milliseconds (0 = manual dismiss only)
  dismissible: bool, // Can user close this notification?
  createdAt: float, // Timestamp for deduplication and lifecycle
}

// Queue state tracks three arrays: pending (waiting), active (showing), archived (history)
type queueState = {
  pending: array<notification>, // Queued but not yet active
  active: array<notification>, // Currently visible (max 3)
  archived: array<notification>, // Recently dismissed (max 10, for undo/history)
  fadingOut: array<string>, // Notifications currently animating out
}

// Maximum number of toasts visible at once
let activeSlotLimit = 3

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Convert importance to string for display/logging
let importanceToString = (imp: importance): string => {
  switch imp {
  | Critical => "critical"
  | Error => "error"
  | Warning => "warning"
  | Success => "success"
  | Info => "info"
  | Transient => "transient"
  }
}

// Convert context to string for display/logging
let contextToString = (ctx: context): string => {
  switch ctx {
  | Operation(op) => "operation:" ++ op
  | UserAction(action) => "action:" ++ action
  | SystemEvent(event) => "event:" ++ event
  }
}

// Default auto-dismiss timeout in milliseconds based on importance
// Critical notifications don't auto-dismiss (manual action required)
let defaultTimeoutMs = (imp: importance): int => {
  switch imp {
  | Critical => 0 // Persist - user must interact
  | Error => 8000 // 8 seconds for error handling
  | Warning => 5000 // 5 seconds for warnings
  | Success => 3000 // 3 seconds for success confirmations
  | Info => 3000 // 3 seconds for informational messages
  | Transient => 2000 // 2 seconds for quick transient messages
  }
}

// Deduplication key - combines context and message to detect duplicates
// Used to prevent toast storms (same operation triggering identical notifications)
let dedupKey = (notif: notification): string => {
  if notif.id != "" {
    "id:" ++ notif.id
  } else {
    contextToString(notif.context) ++ "|" ++ notif.message
  }
}

let contextMessageKey = (notif: notification): string =>
  contextToString(notif.context) ++ "|" ++ notif.message

// Priority ordering for sort comparisons (lower number = higher priority)
// Used to sort notifications so errors appear before success messages
let importancePriority = (imp: importance): int => {
  switch imp {
  | Critical => 0 // Highest priority
  | Error => 1
  | Warning => 2
  | Success => 3
  | Info => 4
  | Transient => 5 // Lowest priority
  }
}
