/* src/components/VisualPipeline/VisualPipelineTypes.res */

open ReBindings

type t = {
  container: Dom.element,
  wrapper: Dom.element,
  mutable dragSourceId: Nullable.t<string>,
  thumbCache: Dict.t<string>,
}
