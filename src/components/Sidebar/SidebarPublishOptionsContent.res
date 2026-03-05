@react.component
let make = (~onOptionsChanged: SidebarBase.SidebarTypes.publishOptions => unit) => {
  let (include4k, setInclude4k) = React.useState(_ => true)
  let (include2k, setInclude2k) = React.useState(_ => true)
  let (includeHd, setIncludeHd) = React.useState(_ => true)
  let (includeStandalone2k, setIncludeStandalone2k) = React.useState(_ => true)
  let (includeLogo, setIncludeLogo) = React.useState(_ => true)
  let (includeMarketing, setIncludeMarketing) = React.useState(_ => true)

  let selectedProfiles = () => {
    let acc = ref([])
    if include4k {
      acc := Belt.Array.concat(acc.contents, [#k4])
    }
    if include2k {
      acc := Belt.Array.concat(acc.contents, [#k2])
    }
    if includeHd {
      acc := Belt.Array.concat(acc.contents, [#hd])
    }
    if includeStandalone2k {
      acc := Belt.Array.concat(acc.contents, [#standalone2k])
    }
    acc.contents
  }

  let toggle4k = () =>
    setInclude4k(prev => {
      let next = !prev
      onOptionsChanged({
        selectedProfiles: {
          let acc = ref([])
          if next {
            acc := Belt.Array.concat(acc.contents, [#k4])
          }
          if include2k {
            acc := Belt.Array.concat(acc.contents, [#k2])
          }
          if includeHd {
            acc := Belt.Array.concat(acc.contents, [#hd])
          }
          if includeStandalone2k {
            acc := Belt.Array.concat(acc.contents, [#standalone2k])
          }
          acc.contents
        },
        includeLogo,
        includeMarketing,
      })
      next
    })

  let toggle2k = () =>
    setInclude2k(prev => {
      let next = !prev
      onOptionsChanged({
        selectedProfiles: {
          let acc = ref([])
          if include4k {
            acc := Belt.Array.concat(acc.contents, [#k4])
          }
          if next {
            acc := Belt.Array.concat(acc.contents, [#k2])
          }
          if includeHd {
            acc := Belt.Array.concat(acc.contents, [#hd])
          }
          if includeStandalone2k {
            acc := Belt.Array.concat(acc.contents, [#standalone2k])
          }
          acc.contents
        },
        includeLogo,
        includeMarketing,
      })
      next
    })

  let toggleHd = () =>
    setIncludeHd(prev => {
      let next = !prev
      onOptionsChanged({
        selectedProfiles: {
          let acc = ref([])
          if include4k {
            acc := Belt.Array.concat(acc.contents, [#k4])
          }
          if include2k {
            acc := Belt.Array.concat(acc.contents, [#k2])
          }
          if next {
            acc := Belt.Array.concat(acc.contents, [#hd])
          }
          if includeStandalone2k {
            acc := Belt.Array.concat(acc.contents, [#standalone2k])
          }
          acc.contents
        },
        includeLogo,
        includeMarketing,
      })
      next
    })

  let toggleStandalone2k = () =>
    setIncludeStandalone2k(prev => {
      let next = !prev
      onOptionsChanged({
        selectedProfiles: {
          let acc = ref([])
          if include4k {
            acc := Belt.Array.concat(acc.contents, [#k4])
          }
          if include2k {
            acc := Belt.Array.concat(acc.contents, [#k2])
          }
          if includeHd {
            acc := Belt.Array.concat(acc.contents, [#hd])
          }
          if next {
            acc := Belt.Array.concat(acc.contents, [#standalone2k])
          }
          acc.contents
        },
        includeLogo,
        includeMarketing,
      })
      next
    })

  <div className="publish-options-panel text-white">
    <div className="publish-options-title"> {React.string("Choose output package")} </div>
    <div className="publish-options-subtitle">
      {React.string("Select the resolutions you want to publish.")}
    </div>

    <div className="publish-options-section">
      <div className="publish-options-section-label"> {React.string("Output formats")} </div>
      <label className="publish-options-row">
        <input type_="checkbox" checked={includeHd} onChange={_ => toggleHd()} className="accent-orange-500" />
        <span> {React.string("HD")} </span>
      </label>
      <label className="publish-options-row">
        <input type_="checkbox" checked={include2k} onChange={_ => toggle2k()} className="accent-orange-500" />
        <span> {React.string("2K")} </span>
      </label>
      <label className="publish-options-row">
        <input type_="checkbox" checked={include4k} onChange={_ => toggle4k()} className="accent-orange-500" />
        <span> {React.string("4K")} </span>
      </label>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeStandalone2k}
          onChange={_ => toggleStandalone2k()}
          className="accent-orange-500"
        />
        <span> {React.string("2K standalone single-file HTML")} </span>
      </label>
    </div>

    <div className="publish-options-divider" />

    <div className="publish-options-section">
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeLogo}
          onChange={_ =>
            setIncludeLogo(prev => {
              let next = !prev
              onOptionsChanged({
                selectedProfiles: selectedProfiles(),
                includeLogo: next,
                includeMarketing,
              })
              next
            })
          }
          className="accent-orange-500"
        />
        <span> {React.string("Include logo branding")} </span>
      </label>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeMarketing}
          onChange={_ =>
            setIncludeMarketing(prev => {
              let next = !prev
              onOptionsChanged({
                selectedProfiles: selectedProfiles(),
                includeLogo,
                includeMarketing: next,
              })
              next
            })
          }
          className="accent-orange-500"
        />
        <span> {React.string("Include marketing strip/contact info")} </span>
      </label>
    </div>
  </div>
}
