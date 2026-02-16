open Vitest
open JournalTypes
open JournalLogic

describe("JournalLogic", () => {
  let mockEntry = (id, status): journalEntry => {
    id,
    operation: "test-op",
    status,
    startTime: 1000.0,
    endTime: None,
    context: JsonCombinators.Json.Encode.object([]),
    retryable: true,
  }

  test("normalizeEntry should convert InProgress to Interrupted", t => {
    let entry = mockEntry("1", InProgress)
    let normalized = normalizeEntry(entry)
    t->expect(normalized.status)->Expect.toBe(Interrupted)
    t->expect(normalized.endTime->Option.isSome)->Expect.toBe(true)
  })

  test("normalizeEntry should preserve other statuses", t => {
    let entry = mockEntry("1", Completed)
    let normalized = normalizeEntry(entry)
    t->expect(normalized.status)->Expect.toBe(Completed)
  })

  test("normalizeJournal should normalize all entries", t => {
    let journal: JournalTypes.t = {
      entries: [mockEntry("1", InProgress), mockEntry("2", Completed)],
      version: 1,
    }
    let normalized = normalizeJournal(journal)
    t
    ->expect((normalized.entries->Belt.Array.get(0)->Belt.Option.getExn).status)
    ->Expect.toEqual(Interrupted)
    t
    ->expect((normalized.entries->Belt.Array.get(1)->Belt.Option.getExn).status)
    ->Expect.toEqual(Completed)
  })

  test("checkEmergencyQueue should add synthetic entry if missing", t => {
    // Mock localStorage
    let _ = %raw(`
      (() => {
        let store = {};
        globalThis.localStorage = {
          getItem: (key) => store[key] || null,
          setItem: (key, value) => { store[key] = value.toString(); },
          removeItem: (key) => { delete store[key]; },
          clear: () => { store = {}; }
        };
      })()
    `)

    let snapshot: emergencySnapshot = {
      id: "emergency-1",
      operation: "upload",
      startTime: 5000.0,
      retryable: true,
    }

    // Set emergency snapshot in mock localStorage
    let raw = JsonCombinators.Json.stringify(emergencySnapshotEncoder(snapshot))
    Dom.Storage2.localStorage->Dom.Storage2.setItem(emergencyQueueKey, raw)

    let emptyJournal: JournalTypes.t = {entries: [], version: 1}
    let restoredJournal = checkEmergencyQueue(emptyJournal)

    t->expect(restoredJournal.entries->Array.length)->Expect.toBe(1)
    let entry = restoredJournal.entries[0]->Option.getOrThrow
    t->expect(entry.id)->Expect.toBe("emergency-1")
    t->expect(entry.status)->Expect.toBe(Interrupted)
  })
})
