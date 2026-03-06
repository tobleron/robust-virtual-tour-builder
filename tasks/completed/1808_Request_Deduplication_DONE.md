# Task 1808: Resilience: Request Deduplication & Idempotency

## 🛡️ Objective
Prevent double-submission of heavy operations (Save, Export, Teaser Generation) caused by rapid user clicks or automated retries.

---

## 🛠️ Execution Roadmap
1. **Logic Implementation**: Create a `RequestDeduplicator.res` utility.
2. **Keying**: Use hash of operation type + parameters to uniquely identify in-flight requests.
3. **Hook**: Inject deduplicator into `AuthenticatedClient.res`.

---

## ✅ Acceptance Criteria
- [ ] Rapidly clicking "Save" only triggers a single network request.
- [ ] Concurrent requests for the same export job are collapsed into one.
