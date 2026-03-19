@react.component
let make = () => {
  <div className="settings-about-wrap">
    <div className="settings-about-card">
      <div className="settings-about-row">
        <span className="settings-about-label"> {React.string("Version")} </span>
        <span className="settings-about-value"> {React.string(Version.getVersionLabel())} </span>
      </div>
      <div className="settings-about-row">
        <span className="settings-about-label"> {React.string("Build")} </span>
        <span className="settings-about-value settings-about-value-mono">
          {React.string(Version.getBuildInfo())}
        </span>
      </div>
    </div>
  </div>
}
