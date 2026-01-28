// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("Shadcn", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  test("Button binding should be valid", t => {
    let el = <Shadcn.Button onClick={_ => ()}> {React.string("test")} </Shadcn.Button>
    t->expect(el)->Expect.toBe(el)
  })

  testAsync("Button should render", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(root, <Shadcn.Button> {React.string("Click Me")} </Shadcn.Button>)

    await wait(50)

    let button = Dom.querySelector(container, "button")
    t->expect(Belt.Option.isSome(Nullable.toOption(button)))->Expect.toBe(true)

    switch Nullable.toOption(button) {
    | Some(el) => t->expect(Dom.getTextContent(el))->Expect.toBe("Click Me")
    | None => ()
    }

    Dom.removeElement(container)
  })

  test("Popover bindings should be valid", t => {
    let el =
      <Shadcn.Popover>
        <Shadcn.Popover.Trigger> {React.string("click")} </Shadcn.Popover.Trigger>
        <Shadcn.Popover.Anchor virtualRef=Nullable.null />
        <Shadcn.Popover.Content> {React.string("content")} </Shadcn.Popover.Content>
      </Shadcn.Popover>
    t->expect(el)->Expect.toBe(el)
  })

  test("Tooltip bindings should be valid", t => {
    let el =
      <Shadcn.Tooltip.Provider delayDuration=100>
        <Shadcn.Tooltip>
          <Shadcn.Tooltip.Trigger asChild=true> {React.string("hover")} </Shadcn.Tooltip.Trigger>
          <Shadcn.Tooltip.Content side="top"> {React.string("tip")} </Shadcn.Tooltip.Content>
        </Shadcn.Tooltip>
      </Shadcn.Tooltip.Provider>
    t->expect(el)->Expect.toBe(el)
  })

  test("DropdownMenu bindings should be valid", t => {
    let el =
      <Shadcn.DropdownMenu>
        <Shadcn.DropdownMenu.Trigger> {React.string("menu")} </Shadcn.DropdownMenu.Trigger>
        <Shadcn.DropdownMenu.Content align="start">
          <Shadcn.DropdownMenu.Group>
            <Shadcn.DropdownMenu.Label> {React.string("Label")} </Shadcn.DropdownMenu.Label>
            <Shadcn.DropdownMenu.Item disabled=true>
              {React.string("Item")}
            </Shadcn.DropdownMenu.Item>
          </Shadcn.DropdownMenu.Group>
          <Shadcn.DropdownMenu.Separator />
          <Shadcn.DropdownMenu.RadioGroup value="one">
            <Shadcn.DropdownMenu.RadioItem value="one">
              {React.string("One")}
            </Shadcn.DropdownMenu.RadioItem>
          </Shadcn.DropdownMenu.RadioGroup>
          <Shadcn.DropdownMenu.Sub>
            <Shadcn.DropdownMenu.SubTrigger> {React.string("Sub")} </Shadcn.DropdownMenu.SubTrigger>
            <Shadcn.DropdownMenu.SubContent>
              <Shadcn.DropdownMenu.Item> {React.string("SubItem")} </Shadcn.DropdownMenu.Item>
            </Shadcn.DropdownMenu.SubContent>
          </Shadcn.DropdownMenu.Sub>
        </Shadcn.DropdownMenu.Content>
      </Shadcn.DropdownMenu>
    t->expect(el)->Expect.toBe(el)
  })

  test("ContextMenu bindings should be valid", t => {
    let el =
      <Shadcn.ContextMenu>
        <Shadcn.ContextMenu.Trigger> {React.string("right click")} </Shadcn.ContextMenu.Trigger>
        <Shadcn.ContextMenu.Content>
          <Shadcn.ContextMenu.Item onClick={_ => ()}>
            {React.string("item")}
          </Shadcn.ContextMenu.Item>
          <Shadcn.ContextMenu.Separator />
        </Shadcn.ContextMenu.Content>
      </Shadcn.ContextMenu>
    t->expect(el)->Expect.toBe(el)
  })

  testAsync("DropdownMenu should render trigger", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <Shadcn.DropdownMenu>
        <Shadcn.DropdownMenu.Trigger asChild=true>
          <button> {React.string("Open Menu")} </button>
        </Shadcn.DropdownMenu.Trigger>
      </Shadcn.DropdownMenu>,
    )

    await wait(50)

    let trigger = Dom.querySelector(container, "button")
    t->expect(Belt.Option.isSome(Nullable.toOption(trigger)))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("ContextMenu should render trigger", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <Shadcn.ContextMenu>
        <Shadcn.ContextMenu.Trigger asChild=true>
          <span id="ctx-trigger"> {React.string("Right click me")} </span>
        </Shadcn.ContextMenu.Trigger>
      </Shadcn.ContextMenu>,
    )

    await wait(50)

    let trigger = Dom.getElementById("ctx-trigger")
    t->expect(Belt.Option.isSome(Nullable.toOption(trigger)))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("Popover should render trigger", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <Shadcn.Popover>
        <Shadcn.Popover.Trigger asChild=true>
          <button id="pop-trigger"> {React.string("Open Popover")} </button>
        </Shadcn.Popover.Trigger>
      </Shadcn.Popover>,
    )

    await wait(50)

    let trigger = Dom.getElementById("pop-trigger")
    t->expect(Belt.Option.isSome(Nullable.toOption(trigger)))->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
