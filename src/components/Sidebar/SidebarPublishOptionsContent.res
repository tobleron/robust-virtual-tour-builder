@react.component
let make = (~onOptionsChanged: SidebarBase.SidebarTypes.publishOptions => unit) => {
  let (include4k, setInclude4k) = React.useState(_ => true)
  let (include2k, setInclude2k) = React.useState(_ => true)
  let (includeHd, setIncludeHd) = React.useState(_ => true)
  let (includeStandalone2k, setIncludeStandalone2k) = React.useState(_ => true)
  let (includeLogo, setIncludeLogo) = React.useState(_ => true)
  let (includeMarketing, setIncludeMarketing) = React.useState(_ => true)

  let buildSelectedProfiles = (
    ~include4kValue,
    ~include2kValue,
    ~includeHdValue,
    ~includeStandalone2kValue,
  ) => {
    let acc = ref([])
    if include4kValue {
      acc := Belt.Array.concat(acc.contents, [#k4])
    }
    if include2kValue {
      acc := Belt.Array.concat(acc.contents, [#k2])
    }
    if includeHdValue {
      acc := Belt.Array.concat(acc.contents, [#hd])
    }
    if includeStandalone2kValue {
      acc := Belt.Array.concat(acc.contents, [#standalone2k])
    }
    acc.contents
  }

  let emitOptions = (
    ~include4kValue=include4k,
    ~include2kValue=include2k,
    ~includeHdValue=includeHd,
    ~includeStandalone2kValue=includeStandalone2k,
    ~includeLogoValue=includeLogo,
    ~includeMarketingValue=includeMarketing,
    (),
  ) => {
    onOptionsChanged({
      selectedProfiles: buildSelectedProfiles(
        ~include4kValue,
        ~include2kValue,
        ~includeHdValue,
        ~includeStandalone2kValue,
      ),
      includeLogo: includeLogoValue,
      includeMarketing: includeMarketingValue,
    })
  }

  let optionLabel = (~label, ~meta="", ()) =>
    <span className="publish-options-row-copy">
      <span className="publish-options-row-title"> {React.string(label)} </span>
      {if meta != "" {
        <span className="publish-options-row-meta"> {React.string(meta)} </span>
      } else {
        React.null
      }}
    </span>

  <div className="publish-options-panel text-white">
    <div className="publish-options-section">
      <div className="publish-options-section-label"> {React.string("Package")} </div>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeHd}
          onChange={_ =>
            setIncludeHd(prev => {
              let next = !prev
              emitOptions(~includeHdValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="HD", ())}
      </label>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={include2k}
          onChange={_ =>
            setInclude2k(prev => {
              let next = !prev
              emitOptions(~include2kValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="2K", ())}
      </label>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={include4k}
          onChange={_ =>
            setInclude4k(prev => {
              let next = !prev
              emitOptions(~include4kValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="4K", ())}
      </label>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeStandalone2k}
          onChange={_ =>
            setIncludeStandalone2k(prev => {
              let next = !prev
              emitOptions(~includeStandalone2kValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="Standalone HTML", ~meta="2K default", ())}
      </label>
    </div>

    <div className="publish-options-divider" />

    <div className="publish-options-section">
      <div className="publish-options-section-label"> {React.string("Extras")} </div>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeLogo}
          onChange={_ =>
            setIncludeLogo(prev => {
              let next = !prev
              emitOptions(~includeLogoValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="Logo branding", ())}
      </label>
      <label className="publish-options-row">
        <input
          type_="checkbox"
          checked={includeMarketing}
          onChange={_ =>
            setIncludeMarketing(prev => {
              let next = !prev
              emitOptions(~includeMarketingValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="Marketing strip", ~meta="contact info", ())}
      </label>
    </div>
  </div>
}
