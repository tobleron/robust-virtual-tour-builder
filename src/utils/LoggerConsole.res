/* src/utils/LoggerConsole.res */

let enabled = ref(Constants.isDebugBuild())
let minLevel = ref(LoggerCommon.Info)
let enabledModules = ref(Belt.Set.String.empty)

let logToConsole = (~module_: string, ~level: LoggerCommon.level, ~message: string, ~data: option<JSON.t>) => {
  if enabled.contents && LoggerCommon.levelPriority(level) >= LoggerCommon.levelPriority(minLevel.contents) {
    let hasFilter = Belt.Set.String.size(enabledModules.contents) > 0
    if !hasFilter || Belt.Set.String.has(enabledModules.contents, module_) {
      let color =
        Dict.get(LoggerCommon.moduleColors, module_)->Option.getOr(
          Dict.get(LoggerCommon.moduleColors, "Default")->Option.getOr("#64748b"),
        )
      let prefix = `%c[${module_}]%c`
      let prefixStyle = `color: ${color}; font-weight: bold;`
      let resetStyle = "color: inherit;"

      let consoleMethod = switch level {
      | Trace | Debug | Perf => "log"
      | Info => "info"
      | Warn => "warn"
      | Error => "error"
      }

      let callConsole: (string, string, string, string, string, Nullable.t<JSON.t>) => unit = %raw(`
        function(method, p1, p2, p3, msg, data) {
          if (data !== null && data !== undefined) {
            console[method](p1, p2, p3, msg, data);
          } else {
            console[method](p1, p2, p3, msg);
          }
        }
      `)

      callConsole(consoleMethod, prefix, prefixStyle, resetStyle, message, data->LoggerCommon.optToNullable)
    }
  }
}
