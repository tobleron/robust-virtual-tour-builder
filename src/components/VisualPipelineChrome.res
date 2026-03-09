type hoverPreview = VisualPipelineHover.hoverPreview
type sceneEdgePath = VisualPipelineEdgeTypes.sceneEdgePath
type sceneEdgeClip = VisualPipelineEdgeTypes.sceneEdgeClip

@react.component
let make = (
  ~isSystemLocked: bool,
  ~activeFloors: array<string>,
  ~linePaths: Dict.t<string>,
  ~wrapperRef,
  ~sceneEdgeClips: array<sceneEdgeClip>,
  ~sceneEdgePaths: array<sceneEdgePath>,
  ~tracks: React.element,
  ~hoverPreview: option<hoverPreview>,
) =>
  <>
    <svg
      className="pipeline-svg-overlay"
      style={ReBindings.makeStyle({
        "height": "400px",
        "width": "100%",
        "top": "auto",
        "bottom": "0",
        "zIndex": "5",
      })}
    >
      {activeFloors
      ->Belt.Array.map(fid =>
        switch linePaths->Dict.get(fid) {
        | Some(d) => <path key={"line-" ++ fid} d className="pipeline-floor-line" />
        | None => React.null
        }
      )
      ->React.array}
    </svg>

    <div
      className="visual-pipeline-wrapper"
      style={ReBindings.makeStyle({"pointerEvents": "none"})}
      ref={wrapperRef->ReactDOM.Ref.domRef}
    >
      <svg className="pipeline-scene-svg-overlay">
        <defs>
          {sceneEdgeClips
          ->Belt.Array.map(clip =>
            <clipPath key={"scene-edge-clip-" ++ clip.id} id={clip.id}>
              <rect
                x={clip.x->Float.toString}
                y={clip.y->Float.toString}
                width={clip.width->Float.toString}
                height={clip.height->Float.toString}
              />
            </clipPath>
          )
          ->React.array}
        </defs>
        {sceneEdgePaths
        ->Belt.Array.map(edge =>
          switch edge.clipId {
          | Some(clipId) =>
            <path
              key={"scene-edge-" ++ edge.id}
              d={edge.d}
              className={edge.className}
              clipPath={"url(#" ++ clipId ++ ")"}
            />
          | None => <path key={"scene-edge-" ++ edge.id} d={edge.d} className={edge.className} />
          }
        )
        ->React.array}
      </svg>

      {tracks}
    </div>

    {switch (hoverPreview, isSystemLocked) {
    | (_, true) => React.null
    | (Some(preview), false) =>
      <div className="pipeline-global-tooltip visible">
        <img src={preview.thumbUrl} className="tooltip-thumb" alt={preview.sceneName ++ " preview"} />
      </div>
    | (None, false) => React.null
    }}
  </>
