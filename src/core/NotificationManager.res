// src/core/NotificationManager.res
// Centralized notification manager with state, listener pattern, and timer management
// Wraps NotificationQueue with stateful behavior and pub/sub event system

open NotificationTypes

// ============================================================================
// MODULE STATE
// ============================================================================

// Current queue state (mutable behind API boundary)
let state: ref<queueState> = ref(NotificationQueue.empty())

// Array of listeners subscribed to state changes
let listeners: ref<array<queueState => unit>> = ref([])

// Map of notification IDs to timeout IDs for auto-dismiss
let timerIds: ref<Belt.Map.String.t<timeoutId>> = ref(Belt.Map.String.empty)

// ============================================================================
// INTERNAL HELPERS
// ============================================================================

// Notify all listeners of state change
let notifyListeners = (newState: queueState): unit => {
  Belt.Array.forEach(listeners.contents, listener => {
    listener(newState)
  })
}

// Placeholder for forward reference (defined below)
let dismissImpl = ref((_notifId: string) => ())

// Schedule auto-dismiss timer for a notification
// If duration > 0, sets timer to dismiss after that many ms
let scheduleAutoDismiss = (notifId: string, duration: int): unit => {
  if duration > 0 {
    let timeoutId = setTimeout(() => {
      dismissImpl.contents(notifId)
    }, duration)
    timerIds := Belt.Map.String.set(timerIds.contents, notifId, timeoutId)
  }
}

// Cancel timeout timer for a notification
// Removes from timer map and clears the timeout
let cancelTimer = (notifId: string): unit => {
  switch Belt.Map.String.get(timerIds.contents, notifId) {
  | Some(timeoutId) => {
      clearTimeout(timeoutId)
      timerIds := Belt.Map.String.remove(timerIds.contents, notifId)
    }
  | None => ()
  }
}

// Generate unique notification ID
// Format: "notif-{timestamp}-{random}"
let generateId = (): string => {
  let timestamp = Int.toString(Int.fromFloat(Date.now()))
  let random = Int.toString(Int.fromFloat(Math.random() *. 1000000.0))
  "notif-" ++ timestamp ++ "-" ++ random
}

let upsertById = (notif: notification, currentState: queueState): queueState => {
  let replaceIfMatch = n =>
    if n.id == notif.id {
      notif
    } else {
      n
    }
  {
    ...currentState,
    pending: Belt.Array.map(currentState.pending, replaceIfMatch),
    active: Belt.Array.map(currentState.active, replaceIfMatch),
  }
}

// ============================================================================
// PUBLIC API
// ============================================================================

// Dispatch a notification to the queue
// - Assigns ID if needed
// - Adds to queue (may deduplicate)
// - Schedules auto-dismiss timer
// - Notifies all listeners
let dispatch = (notif: notification): unit => {
  Logger.info(
    ~module_="NotificationManager",
    ~message="DISPATCHING_NOTIFICATION",
    ~data=Some({"message": notif.message}),
    (),
  )
  let withId = {
    ...notif,
    id: if notif.id === "" {
      generateId()
    } else {
      notif.id
    },
  }

  let existing = NotificationQueue.getById(withId.id, state.contents)

  switch existing {
  | Some(_) => state := upsertById(withId, state.contents)
  | None =>
    // Add to queue
    state := NotificationQueue.enqueue(withId, state.contents)

    // Try to move from pending to active if space is available
    state := NotificationQueue.dequeue(state.contents)
  }

  // Schedule auto-dismiss if needed
  cancelTimer(withId.id)
  scheduleAutoDismiss(withId.id, withId.duration)

  // Notify listeners of new state
  Logger.info(
    ~module_="NotificationManager",
    ~message="STATE_AFTER_DISPATCH",
    ~data=Some({
      "pendingCount": Belt.Array.length(state.contents.pending),
      "activeCount": Belt.Array.length(state.contents.active),
    }),
    (),
  )
  notifyListeners(state.contents)
}

// Subscribe to state changes
// Returns unsubscribe function
let subscribe = (listener: queueState => unit): (unit => unit) => {
  listeners := Belt.Array.concat(listeners.contents, [listener])

  // Return unsubscribe function
  () => {
    listeners := Belt.Array.keep(listeners.contents, l => l !== listener)
  }
}

// Get current queue state
let getState = (): queueState => {
  state.contents
}

// Dismiss a notification by ID
// - Cancels auto-dismiss timer
// - Removes from active queue
// - Moves to archived
// - Notifies listeners
let dismiss = (notifId: string): unit => {
  cancelTimer(notifId)
  state := NotificationQueue.dismiss(notifId, state.contents)
  // Pull next notification from pending
  state := NotificationQueue.dequeue(state.contents)
  notifyListeners(state.contents)
}

// Initialize forward reference so scheduleAutoDismiss can call dismiss
let () = dismissImpl := dismiss

// Clear all notifications and timers
// Resets queue to empty state
let clear = (): unit => {
  // Cancel all timers
  Belt.Map.String.forEach(timerIds.contents, (_key, timeoutId) => {
    clearTimeout(timeoutId)
  })
  timerIds := Belt.Map.String.empty

  // Clear queue state
  state := NotificationQueue.empty()

  // Notify listeners
  notifyListeners(state.contents)
}
