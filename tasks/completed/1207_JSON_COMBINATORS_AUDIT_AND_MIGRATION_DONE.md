# TASK: JSON Combinators Audit & Migration

**Priority**: 🟡 Medium
**Estimated Effort**: Medium (2-3 hours)
**Dependencies**: None
**Related Tasks**: All robustness tasks

---

## 1. Problem Statement

The project mandates `rescript-json-combinators` for all JSON encoding/decoding (per GEMINI.md rules), but there may be legacy usages of:

- Direct `JSON.stringify` with object literals
- Manual JSON object construction
- Legacy `JSON` module usage
- Unsafe `%raw` JSON handling

This task audits the codebase and migrates any non-compliant patterns.

---

## 2. Audit Scope

### Files to Scan

```bash
# Find potential violations
grep -rn "JSON.stringify" src/ --include="*.res"
grep -rn "JSON.parse" src/ --include="*.res"
grep -rn "JSON.Encode" src/ --include="*.res"
grep -rn "JSON.Decode" src/ --include="*.res"
grep -rn "%raw.*JSON" src/ --include="*.res"
```

### Allowed Patterns

```rescript
// ✅ ALLOWED: JsonCombinators usage
open JsonCombinators.Json.Encode
let encoder = object([("key", string(value))])

// ✅ ALLOWED: Logger.castToJson (internal use)
Logger.debug(~data=Logger.castToJson({...}), ...)

// ✅ ALLOWED: JSON.t type annotations
let data: JSON.t = ...
```

### Forbidden Patterns

```rescript
// ❌ FORBIDDEN: Direct JSON module usage
let json = JSON.Encode.object([...])
let value = JSON.Decode.string(json)

// ❌ FORBIDDEN: Raw stringify
let str = JSON.stringify(obj)

// ❌ FORBIDDEN: Raw parse
let obj = JSON.parse(str)

// ❌ FORBIDDEN: Raw JSON in %raw
let x = %raw(`JSON.stringify({...})`)
```

---

## 3. Migration Guide

### Before (Non-Compliant)

```rescript
let sendTelemetry = (entries) => {
  let payload = JSON.stringify(entries)
  Fetch.fetch(url, ~body=payload, ...)
}
```

### After (Compliant)

```rescript
let telemetryEntryEncoder = JsonCombinators.Json.Encode.object([
  ("timestamp", float(entry.timestamp)),
  ("module", string(entry.module_)),
  ("level", string(entry.level)),
  ("message", string(entry.message)),
  ("data", nullable(id, entry.data)),
])

let sendTelemetry = (entries) => {
  let encoder = JsonCombinators.Json.Encode.array(telemetryEntryEncoder)
  let payload = JsonCombinators.Json.encode(encoder(entries))
  Fetch.fetch(url, ~body=payload, ...)
}
```

---

## 4. Files Requiring Review

Based on initial analysis, these files may need updates:

| File | Concern | Priority |
|------|---------|----------|
| `src/utils/LoggerTelemetry.res` | Telemetry batch encoding | High |
| `src/systems/ProjectManager.res` | Project data serialization | Medium |
| `src/systems/UploadProcessor.res` | Progress updates | Low |
| `src/components/NotificationContext.res` | Notification data | Low |
| `src/systems/EventBus.res` | Event data encoding | Low |

---

## 5. Encoder Registry

Create a centralized encoder registry for reuse:

**File**: `src/core/JsonEncoders.res` (if not exists, add to `JsonParsers.res`)

```rescript
module Telemetry = {
  let entry = JsonCombinators.Json.Encode.object([
    ("timestampMs", float),
    ("module", string),
    ("level", string),
    ("message", string),
    ("data", optional(id)),
  ])
  
  let batch = array(entry)
}

module Notification = {
  let payload = JsonCombinators.Json.Encode.object([
    ("message", string),
    ("type", string),
    ("data", optional(id)),
  ])
}
```

---

## 6. Verification Criteria

- [ ] `grep -rn "JSON.stringify" src/ --include="*.res"` returns no results.
- [ ] `grep -rn "JSON.parse" src/ --include="*.res"` returns no results.
- [ ] All JSON encoding uses `JsonCombinators.Json.Encode`.
- [ ] All JSON decoding uses `JsonCombinators.Json.Decode`.
- [ ] No CSP violations in production build.
- [ ] `npm run build` completes with zero warnings.

---

## 7. File Checklist

- [ ] `src/utils/LoggerTelemetry.res` - Migrate to combinators
- [ ] `src/core/JsonParsers.res` - Add/verify Telemetry encoders
- [ ] All files in audit scan - Review and migrate
- [ ] `docs/JSON_ENCODING_STANDARD.md` - Document standard (optional)

---

## 8. References

- `GEMINI.md` - Project rules on JSON handling
- `src/core/JsonParsers.res` - Existing encoder patterns
- [rescript-json-combinators docs](https://github.com/glennsl/rescript-json-combinators)
- `.agent/workflows/csp-validation-migration.md`
