@scope(("window", "location")) @val external reload: unit => unit = "reload"

@react.component
let make = (~featureName: string) => {
  <div className="w-full h-full flex items-center justify-center p-4">
    <div className="max-w-md w-full rounded-xl border border-orange-400/40 bg-slate-900/85 text-white p-4">
      <h3 className="text-base font-semibold mb-2"> {React.string(featureName ++ " crashed")} </h3>
      <p className="text-sm text-slate-200 leading-relaxed">
        {React.string(
          "This area failed to render. Other parts of the app remain available. Reload to fully recover.",
        )}
      </p>
      <button
        className="mt-4 px-3 py-2 rounded-md bg-orange-500/80 hover:bg-orange-500 text-white text-sm font-semibold"
        onClick={_ => reload()}
      >
        {React.string("Reload application")}
      </button>
    </div>
  </div>
}
