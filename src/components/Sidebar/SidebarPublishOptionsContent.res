@react.component
let make = (~onOptionsChanged: SidebarBase.SidebarTypes.publishOptions => unit) => {
  let (includeWebPackage, setIncludeWebPackage) = React.useState(_ => true)
  let (includeStandalone2k, setIncludeStandalone2k) = React.useState(_ => false)
  let (includeLogo, setIncludeLogo) = React.useState(_ => true)
  let (includeMarketing, setIncludeMarketing) = React.useState(_ => true)

  let buildSelectedProfiles = (~includeWebPackageValue, ~includeStandalone2kValue) => {
    let acc = ref([])
    if includeWebPackageValue {
      acc := Belt.Array.concat(acc.contents, [#k4, #k2])
    }
    if includeStandalone2kValue {
      acc := Belt.Array.concat(acc.contents, [#standalone2k])
    }
    acc.contents
  }

  let emitOptions = (
    ~includeWebPackageValue=includeWebPackage,
    ~includeStandalone2kValue=includeStandalone2k,
    ~includeLogoValue=includeLogo,
    ~includeMarketingValue=includeMarketing,
    (),
  ) => {
    onOptionsChanged({
      selectedProfiles: buildSelectedProfiles(~includeWebPackageValue, ~includeStandalone2kValue),
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
          checked={includeWebPackage}
          onChange={_ =>
            setIncludeWebPackage(prev => {
              let next = !prev
              emitOptions(~includeWebPackageValue=next, ())
              next
            })}
          className="accent-orange-500"
        />
        {optionLabel(~label="Web Package", ~meta="4K default, 2K on small phones", ())}
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
