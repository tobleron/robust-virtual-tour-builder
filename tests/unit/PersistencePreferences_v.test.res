open Vitest

describe("PersistencePreferences", () => {
  test("autosave mode round-trips to stable storage values", t => {
    t
    ->expect(PersistencePreferences.autosaveModeToString(PersistencePreferences.Off))
    ->Expect.toBe("off")
    t
    ->expect(PersistencePreferences.autosaveModeToString(PersistencePreferences.LocalOnly))
    ->Expect.toBe("local-only")
    t
    ->expect(PersistencePreferences.autosaveModeToString(PersistencePreferences.Hybrid))
    ->Expect.toBe("hybrid")
    t
    ->expect(PersistencePreferences.autosaveModeFromString("off"))
    ->Expect.toEqual(PersistencePreferences.Off)
    t
    ->expect(PersistencePreferences.autosaveModeFromString("local-only"))
    ->Expect.toEqual(PersistencePreferences.LocalOnly)
    t
    ->expect(PersistencePreferences.autosaveModeFromString("hybrid"))
    ->Expect.toEqual(PersistencePreferences.Hybrid)
  })

  test("unknown autosave mode falls back to the default", t => {
    t
    ->expect(PersistencePreferences.autosaveModeFromString("unexpected"))
    ->Expect.toEqual(PersistencePreferences.default.autosaveMode)
  })

  test("snapshot cadence round-trips to stable storage values", t => {
    t
    ->expect(PersistencePreferences.snapshotCadenceToString(PersistencePreferences.Conservative))
    ->Expect.toBe("conservative")
    t
    ->expect(PersistencePreferences.snapshotCadenceToString(PersistencePreferences.Balanced))
    ->Expect.toBe("balanced")
    t
    ->expect(PersistencePreferences.snapshotCadenceToString(PersistencePreferences.Frequent))
    ->Expect.toBe("frequent")
    t
    ->expect(PersistencePreferences.snapshotCadenceFromString("conservative"))
    ->Expect.toEqual(PersistencePreferences.Conservative)
    t
    ->expect(PersistencePreferences.snapshotCadenceFromString("balanced"))
    ->Expect.toEqual(PersistencePreferences.Balanced)
    t
    ->expect(PersistencePreferences.snapshotCadenceFromString("frequent"))
    ->Expect.toEqual(PersistencePreferences.Frequent)
  })

  test("unknown snapshot cadence falls back to the default", t => {
    t
    ->expect(PersistencePreferences.snapshotCadenceFromString("unexpected"))
    ->Expect.toEqual(PersistencePreferences.default.snapshotCadence)
  })

  test("save target round-trips to stable storage values", t => {
    t
    ->expect(PersistencePreferences.saveTargetToString(PersistencePreferences.Offline))
    ->Expect.toBe("offline")
    t
    ->expect(PersistencePreferences.saveTargetToString(PersistencePreferences.Server))
    ->Expect.toBe("server")
    t
    ->expect(PersistencePreferences.saveTargetToString(PersistencePreferences.Both))
    ->Expect.toBe("both")
    t
    ->expect(PersistencePreferences.saveTargetFromString("offline"))
    ->Expect.toEqual(PersistencePreferences.Offline)
    t
    ->expect(PersistencePreferences.saveTargetFromString("server"))
    ->Expect.toEqual(PersistencePreferences.Server)
    t
    ->expect(PersistencePreferences.saveTargetFromString("both"))
    ->Expect.toEqual(PersistencePreferences.Both)
  })

  test("unknown save target falls back to the default", t => {
    t
    ->expect(PersistencePreferences.saveTargetFromString("unexpected"))
    ->Expect.toEqual(PersistencePreferences.default.preferredSaveTarget)
  })
})
