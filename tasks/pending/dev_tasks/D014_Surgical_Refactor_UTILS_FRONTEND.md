# Task D014: Surgical Refactor UTILS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../src/utils/OperationJournal.res** (Metric: [Nesting: 1.80, Density: 0.02, Coupling: 0.04] | Drag: 2.82 | LOC: 405/300  🎯 Target: Function: `isTerminalStatus` (High Local Complexity (3.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D014/verification.json` (files at `_dev-system/tmp/D014/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D014/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/utils/OperationJournal.res`
- `src/utils/OperationJournal.res` (53 functions, fingerprint c359888c7391be20d409dd61d7e9718e7adb211764adf4f1c564a2caa3ec336a)
    - journalKey — let journalKey = "operation_journal"
    - emergencyQueueKey — let emergencyQueueKey = "operation_journal_emergency_queue"
    - journalVersion — let journalVersion = 2
    - emergencySnapshotEncoder — let emergencySnapshotEncoder = (snapshot: emergencySnapshot) => {
    - emergencySnapshotDecoder — let emergencySnapshotDecoder = Decode.object(field => {
    - isTerminalStatus — let isTerminalStatus = (status: operationStatus) => {
    - saveToEmergencyQueue — let saveToEmergencyQueue = (entry: journalEntry) => {
    - snapshot — let snapshot: emergencySnapshot = {
    - raw — let raw = JsonCombinators.Json.stringify(emergencySnapshotEncoder(snapshot))
    - clearEmergencyQueueForId — let clearEmergencyQueueForId = (id: string) => {
    - checkEmergencyQueue — let checkEmergencyQueue = (journal: t): t => {
    - hasEntry — let hasEntry = journal.entries->Belt.Array.some(entry => entry.id == snapshot.id)
    - syntheticEntry — let syntheticEntry: journalEntry = {
    - newEntries — let newEntries = Belt.Array.concat(journal.entries, [syntheticEntry])
    - normalizeEntry — let normalizeEntry = (entry: journalEntry) => {
    - make — let make = () => {
    - normalizeJournal — let normalizeJournal = (journal: t): t => {
    - currentJournal — let currentJournal = ref(make())
    - statusEncoder — let statusEncoder = (status: operationStatus) => {
    - journalEntryEncoder — let journalEntryEncoder = (entry: journalEntry) => {
    - journalEncoder — let journalEncoder = (journal: t) => {
    - statusDecoder — let statusDecoder = {
    - status — let status = field.required("status", Decode.string)
    - error — let error = field.required("error", Decode.string)
    - journalEntryDecoder — let journalEntryDecoder = Decode.object(field => {
    - journalDecoder — let journalDecoder = Decode.object(field => {
    - save — let save = (journal: t) => {
    - json — let json = journalEncoder(journal)
    - saveCurrent — let saveCurrent = () => {
    - load — let load = () => {
    - json — let json = asJson(stored)
    - fixedJournal — let fixedJournal = decodedJournal->checkEmergencyQueue->normalizeJournal
    - newJournal — let newJournal = make()
    - newJournal — let newJournal = make()
    - newJournal — let newJournal = make()
    - newJournal — let newJournal = make()
    - generateId — let generateId = () => {
    - random — let random = Math.random() *. 1000000.0
    - startOperation — let startOperation = (~operation: string, ~context: JSON.t, ~retryable: bool) => {
    - id — let id = generateId()
    - entry — let entry: journalEntry = {
    - newEntries — let newEntries = Belt.Array.concat(currentJournal.contents.entries, [entry])
    - updateStatus — let updateStatus = (id: string, status: operationStatus): Promise.t<unit> => {
    - now — let now = Date.now()
    - found — let found = ref(false)
    - newEntries — let newEntries = currentJournal.contents.entries->Belt.Array.map(entry => {
    - nextEndTime — let nextEndTime = switch status {
    - updateContext — let updateContext = (id: string, context: JSON.t): Promise.t<unit> => {
    - newEntries — let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    - completeOperation — let completeOperation = (id: string): Promise.t<unit> => {
    - failOperation — let failOperation = (id: string, reason: string): Promise.t<unit> => {
    - getInterrupted — let getInterrupted = (journal: t) => {
    - getPending — let getPending = (journal: t) => {
