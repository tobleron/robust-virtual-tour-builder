@react.component
let make = (~entries: array<OperationJournal.journalEntry>) => {
  <div className="flex flex-col gap-3 p-2 text-sm text-slate-700">
    <p>{React.string("The following operations were interrupted during the last session:")}</p>
    <div className="flex flex-col gap-2 max-h-60 overflow-y-auto">
      {entries->Belt.Array.map(entry => {
        let statusStr = switch entry.status {
        | Pending => "Pending"
        | InProgress => "In Progress"
        | Completed => "Completed"
        | Failed(msg) => "Failed: " ++ msg
        | Interrupted => "Interrupted"
        | Cancelled => "Cancelled"
        }

        let dateStr = Date.fromTime(entry.startTime)->Date.toLocaleString

        <div key=entry.id className="bg-red-50 p-3 rounded border border-red-100 flex flex-col gap-1">
           <div className="flex justify-between items-center">
             <span className="font-semibold text-red-800">{React.string(entry.operation)}</span>
             <span className="text-xs text-red-600">{React.string(dateStr)}</span>
           </div>
           <div className="text-xs text-red-700">
             {React.string("Status: " ++ statusStr)}
           </div>
           <div className="text-xs font-mono bg-white/50 p-1 mt-1 rounded text-slate-600 break-all">
             {React.string(JsonCombinators.Json.stringify(entry.context))}
           </div>
        </div>
      })->React.array}
    </div>
    <p className="text-xs text-slate-500 mt-2">
      {React.string("You can attempt to retry these operations, or dismiss this message to clear the journal.")}
    </p>
  </div>
}
