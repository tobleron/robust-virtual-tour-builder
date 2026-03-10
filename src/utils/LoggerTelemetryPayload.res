/* src/utils/LoggerTelemetryPayload.res */

open LoggerCommon

let sanitizeJson = (_entry: JSON.t, _fields: array<string>): JSON.t =>
  %raw(`(function(_entry, _fields) {
    if (!_entry || typeof _entry !== 'object') {
      return _entry;
    }
    const sanitized = {..._entry};
    for (let idx = 0; idx < _fields.length; idx++) {
      const key = _fields[idx];
      if (Object.prototype.hasOwnProperty.call(sanitized, key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    return sanitized;
  })(_entry, _fields)`)

let sanitizePayload = (data: option<JSON.t>): option<JSON.t> =>
  data->Option.map(json => sanitizeJson(json, Constants.Telemetry.sensitiveFields))

let encodeLogEntry = (entry: logEntry) => {
  let encode = JsonCombinators.Json.Encode.object
  let float = JsonCombinators.Json.Encode.float
  let string = JsonCombinators.Json.Encode.string
  let option = JsonCombinators.Json.Encode.option
  let id = (v: JSON.t) => v

  encode([
    ("timestampMs", float(entry.timestampMs)),
    ("timestamp", string(entry.timestamp)),
    ("module", string(entry.module_)),
    ("level", string(entry.level)),
    ("message", string(entry.message)),
    ("data", option(id)(entry.data)),
    ("priority", string(entry.priority)),
    ("requestId", option(string)(entry.requestId)),
    ("operationId", option(string)(entry.operationId)),
    ("sessionId", option(string)(entry.sessionId)),
  ])
}

let encodeTelemetryBatch = (batch: telemetryBatch) => {
  let encode = JsonCombinators.Json.Encode.object
  let array = JsonCombinators.Json.Encode.array

  encode([("entries", array(encodeLogEntry)(batch.entries))])
}

let deduplicateBatchEntries = (_entries: array<logEntry>): array<logEntry> =>
  %raw(`(function(_entries) {
    const grouped = new Map();
    for (const entry of _entries) {
      const key = [
        entry.module,
        entry.level,
        entry.message,
        entry.priority,
        entry.requestId || "",
        entry.operationId || "",
        entry.sessionId || "",
        JSON.stringify(entry.data || null)
      ].join("|");
      const current = grouped.get(key);
      if (current) {
        current.__count = (current.__count || 1) + 1;
        if ((entry.timestampMs || 0) > (current.timestampMs || 0)) {
          current.timestampMs = entry.timestampMs;
          current.timestamp = entry.timestamp;
        }
      } else {
        grouped.set(key, {...entry, __count: 1});
      }
    }

    const merged = [];
    for (const item of grouped.values()) {
      const count = item.__count || 1;
      if (count > 1) {
        const baseData = item.data && typeof item.data === "object" && !Array.isArray(item.data)
          ? {...item.data}
          : {};
        baseData.count = count;
        item.data = baseData;
      }
      delete item.__count;
      merged.push(item);
    }
    return merged;
  })(_entries)`)
