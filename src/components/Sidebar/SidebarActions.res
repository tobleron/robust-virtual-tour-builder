/* src/components/Sidebar/SidebarActions.res */

@react.component
let make = React.memo((
  ~onNew,
  ~onSave,
  ~onLoad,
  ~onAbout,
  ~onExport,
  ~onTeaser,
  ~exportReady,
  ~teaserReady,
) => {
  React.useEffect0(() => {
    Logger.initialized(~module_="SidebarActions")
    None
  })

  <div className="px-5 pb-6">
    <div className="grid grid-cols-4 gap-2 mb-3">
      {[
        ("file-plus", "New", onNew),
        ("save", "Save", onSave),
        ("folder-open", "Load", onLoad),
        ("info", "About", onAbout),
      ]
      ->Belt.Array.mapWithIndex((i, (icon, label, onClick)) =>
        <button
          key={Int.toString(i)}
          className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
          onClick={_ => onClick()}
          ariaLabel={label}
        >
          {switch icon {
          | "file-plus" => <LucideIcons.FilePlus size=20 strokeWidth=1.0 />
          | "save" => <LucideIcons.Save size=20 strokeWidth=1.0 />
          | "folder-open" => <LucideIcons.FolderOpen size=20 strokeWidth=1.0 />
          | "info" => <LucideIcons.Info size=20 strokeWidth=1.0 />
          | _ => React.null
          }}
          <span> {React.string(label)} </span>
        </button>
      )
      ->React.array}
    </div>

    <div className="grid grid-cols-2 gap-2">
      <button
        className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
        disabled={!exportReady}
        onClick={_ => onExport()}
        ariaLabel="Export Tour"
      >
        <LucideIcons.Download
          className="text-white transition-all duration-300" size=20 strokeWidth=1.0
        />
        <span> {React.string("Export")} </span>
      </button>

      <button
        className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
        disabled={!teaserReady}
        onClick={_ => onTeaser()}
        ariaLabel="Create Teaser"
      >
        <LucideIcons.Film
          className="text-white transition-all duration-300" size=20 strokeWidth=1.0
        />
        <span> {React.string("Teaser")} </span>
      </button>
    </div>
  </div>
})
