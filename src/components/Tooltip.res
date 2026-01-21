/* src/components/Tooltip.res */

@react.component
let make = (~children: React.element, ~content: string, ~alignment: PopOver.alignment=#Auto) => {
  let (isOpen, setIsOpen) = React.useState(_ => false)
  let triggerRef = React.useRef(Nullable.null)

  let handleMouseEnter = _ => setIsOpen(_ => true)
  let handleMouseLeave = _ => setIsOpen(_ => false)

  <div
    ref={ReactDOM.Ref.domRef(triggerRef)}
    className="inline-flex items-center justify-center p-0 m-0 border-none bg-none outline-none appearance-none"
    onMouseEnter={handleMouseEnter}
    onMouseLeave={handleMouseLeave}
  >
    children
    {switch (isOpen, Nullable.toOption(triggerRef.current)) {
    | (true, Some(anchor)) =>
      <PopOver anchor onClose={() => setIsOpen(_ => false)} offset=6.0 alignment isTooltip=true>
        <div
          className="px-3 py-1.5 bg-slate-900/90 text-white text-[10px] font-black uppercase tracking-widest rounded-lg shadow-xl backdrop-blur-md border border-white/10 pointer-events-none animate-fade-in whitespace-nowrap"
        >
          {React.string(content)}
        </div>
      </PopOver>
    | _ => React.null
    }}
  </div>
}
