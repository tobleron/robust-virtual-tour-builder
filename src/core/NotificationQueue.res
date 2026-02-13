// src/core/NotificationQueue.res
// Pure stateless queue logic for notification lifecycle management
// All functions are pure - take queueState, return new queueState
// No side effects, no mutable state, fully testable

open NotificationTypes

let maxActive = NotificationTypes.activeSlotLimit

// Create an empty queue state
let empty = (): queueState => {
  pending: [],
  active: [],
  archived: [],
  fadingOut: [],
}

// Sort notifications by importance priority (lower number = higher priority)
// Simple implementation: iterate and build sorted result
let sortByImportance = (notifications: array<notification>): array<notification> => {
  notifications->Array.toSorted((a, b) => {
    (importancePriority(a.importance) - importancePriority(b.importance))->Int.toFloat
  })
}

// Check if a notification is a duplicate of an existing pending notification
// Deduplication: same dedupKey within 2 seconds = considered duplicate
let shouldDeduplicate = (notif: notification, state: queueState): bool => {
  let key = dedupKey(notif)
  let now = Date.now()
  let twoSecsMs = 2000.0

  Belt.Array.some(state.pending, existingNotif => {
    dedupKey(existingNotif) === key && now -. existingNotif.createdAt < twoSecsMs
  })
}

// Add notification to queue
// If duplicate (same key within 2s), skip
// Otherwise, add to pending and sort by importance
let enqueue = (notif: notification, state: queueState): queueState => {
  if shouldDeduplicate(notif, state) {
    // Skip this notification - it's a duplicate
    state
  } else {
    // Add to pending and re-sort
    let newPending = Belt.Array.concat(state.pending, [notif])
    {
      ...state,
      pending: sortByImportance(newPending),
    }
  }
}

// Move first pending notification to active array
// Only if: active array has space (<3) AND pending array has items
let dequeue = (state: queueState): queueState => {
  let activeCount = Belt.Array.length(state.active)
  let pendingCount = Belt.Array.length(state.pending)

  if activeCount >= maxActive || pendingCount === 0 {
    state
  } else {
    switch Belt.Array.get(state.pending, 0) {
    | Some(notif) => {
        let rest = Belt.Array.slice(state.pending, ~offset=1, ~len=pendingCount - 1)
        {
          ...state,
          pending: rest,
          active: Belt.Array.concat(state.active, [notif]),
        }
      }
    | None => state
    }
  }
}

// Helper: find first matching element
let findFirst = (predicate: 'a => bool, arr: array<'a>): option<'a> => {
  let result = ref(None)
  Belt.Array.forEach(arr, item => {
    if predicate(item) && Belt.Option.isNone(result.contents) {
      result := Some(item)
    }
  })
  result.contents
}

let findByContextKey = (key: string, state: queueState): option<notification> => {
  let matchKey = notif => NotificationTypes.contextMessageKey(notif) == key
  switch findFirst(matchKey, state.active) {
  | Some(existing) => Some(existing)
  | None => findFirst(matchKey, state.pending)
  }
}

// Dismiss a notification by ID
// Remove from active, add to archived (keep max 10)
let dismiss = (notifId: string, state: queueState): queueState => {
  let newActive = Belt.Array.keep(state.active, notif => notif.id !== notifId)
  let dismissedOpt = findFirst(notif => notif.id === notifId, state.active)
  let newFadingOut = Belt.Array.keep(state.fadingOut, id => id !== notifId)

  switch dismissedOpt {
  | Some(dismissed) => {
      let newArchived = Belt.Array.concat(state.archived, [dismissed])
      let archivedCount = Belt.Array.length(newArchived)
      let trimmedArchived = if archivedCount > 10 {
        Belt.Array.slice(newArchived, ~offset=archivedCount - 10, ~len=10)
      } else {
        newArchived
      }
      {
        pending: state.pending,
        active: newActive,
        archived: trimmedArchived,
        fadingOut: newFadingOut,
      }
    }
  | None => {
      pending: state.pending,
      active: newActive,
      archived: state.archived,
      fadingOut: newFadingOut,
    }
  }
}

// Find notification by ID across all arrays
let getById = (notifId: string, state: queueState): option<notification> => {
  // Search pending first
  let inPending = findFirst(n => n.id === notifId, state.pending)
  switch inPending {
  | Some(n) => Some(n)
  | None => {
      // Search active
      let inActive = findFirst(n => n.id === notifId, state.active)
      switch inActive {
      | Some(n) => Some(n)
      | None => findFirst(n => n.id === notifId, state.archived)
      }
    }
  }
}
