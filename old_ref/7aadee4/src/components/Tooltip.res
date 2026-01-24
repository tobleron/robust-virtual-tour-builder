/* src/components/Tooltip.res */

@react.component
let make = (
  ~children: React.element,
  ~content: string,
  ~alignment: PopOver.alignment=#Auto,
  ~disabled: bool=false,
  ~delayDuration: option<int>=?,
) => {
  if disabled {
    children
  } else {
    let side = switch alignment {
    | #Right => "right"
    | #Left => "left"
    | #TopLeft | #TopRight => "top"
    | #BottomLeft | #BottomRight => "bottom"
    | #Auto => "bottom"
    }

    <Shadcn.Tooltip ?delayDuration>
      <Shadcn.Tooltip.Trigger asChild=true> children </Shadcn.Tooltip.Trigger>
      <Shadcn.Tooltip.Content side sideOffset=8> {React.string(content)} </Shadcn.Tooltip.Content>
    </Shadcn.Tooltip>
  }
}
