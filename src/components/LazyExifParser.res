let lazyComponent = React.lazy_(() =>
  %raw(`import("../systems/ExifParser.bs.js").then(m => ({default: m.make}))`)
)

@react.component
let make = () => {
  <React.Suspense fallback={<div className="lazy-loading-spinner" />}>
    {React.createElement(lazyComponent, ())}
  </React.Suspense>
}
