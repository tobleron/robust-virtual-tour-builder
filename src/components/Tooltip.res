/* src/components/Tooltip.res */

@react.component
let make = (~children: React.element, ~content: string, ~alignment: PopOver.alignment=#Auto) => {
  let side = switch alignment {
  | #Right => "right"
  | #Left => "left"
  | #TopLeft | #TopRight => "top"
  | #BottomLeft | #BottomRight => "bottom"
  | #Auto => "bottom"
  }

  <Shadcn.Tooltip>
    <Shadcn.Tooltip.Trigger asChild=true> children </Shadcn.Tooltip.Trigger>
    <Shadcn.Tooltip.Content
      side
      sideOffset=8
      className="bg-[#001a38] text-white text-[10px] font-black uppercase tracking-[0.1em] rounded-lg shadow-[0_8px_30px_rgb(0,0,0,0.5)] border-l-4 border-accent px-4 py-2"
    >
      {React.string(content)}
    </Shadcn.Tooltip.Content>
  </Shadcn.Tooltip>
}
