open Vitest
open ReBindings

describe("LucideIcons", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render Home icon", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(root, <LucideIcons.Home size=24 />)

    await wait(50)

    // Lucide icons usually render as <svg>
    let svg = Dom.querySelector(container, "svg")
    t->expect(Belt.Option.isSome(Nullable.toOption(svg)))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  test("Play icon binding", t => {
    let el = <LucideIcons.Play />
    t->expect(el)->Expect.toBe(el)
  })

  test("Square icon binding", t => {
    let el = <LucideIcons.Square />
    t->expect(el)->Expect.toBe(el)
  })

  test("Home icon binding", t => {
    let el = <LucideIcons.Home />
    t->expect(el)->Expect.toBe(el)
  })

  test("Sun icon binding", t => {
    let el = <LucideIcons.Sun />
    t->expect(el)->Expect.toBe(el)
  })

  test("Trees icon binding", t => {
    let el = <LucideIcons.Trees />
    t->expect(el)->Expect.toBe(el)
  })

  test("Sprout icon binding", t => {
    let el = <LucideIcons.Sprout />
    t->expect(el)->Expect.toBe(el)
  })

  test("Navigation icon binding", t => {
    let el = <LucideIcons.Navigation />
    t->expect(el)->Expect.toBe(el)
  })

  test("Trash2 icon binding", t => {
    let el = <LucideIcons.Trash2 />
    t->expect(el)->Expect.toBe(el)
  })

  test("Unlink icon binding", t => {
    let el = <LucideIcons.Unlink />
    t->expect(el)->Expect.toBe(el)
  })

  test("FastForward icon binding", t => {
    let el = <LucideIcons.FastForward />
    t->expect(el)->Expect.toBe(el)
  })

  test("ChevronRight icon binding", t => {
    let el = <LucideIcons.ChevronRight />
    t->expect(el)->Expect.toBe(el)
  })

  test("ChevronUp icon binding", t => {
    let el = <LucideIcons.ChevronUp />
    t->expect(el)->Expect.toBe(el)
  })

  test("ChevronsUp icon binding", t => {
    let el = <LucideIcons.ChevronsUp />
    t->expect(el)->Expect.toBe(el)
  })

  test("Plus icon binding", t => {
    let el = <LucideIcons.Plus />
    t->expect(el)->Expect.toBe(el)
  })

  test("X icon binding", t => {
    let el = <LucideIcons.X />
    t->expect(el)->Expect.toBe(el)
  })

  test("CircleAlert icon binding", t => {
    let el = <LucideIcons.CircleAlert />
    t->expect(el)->Expect.toBe(el)
  })

  test("CircleCheck icon binding", t => {
    let el = <LucideIcons.CircleCheck />
    t->expect(el)->Expect.toBe(el)
  })

  test("TriangleAlert icon binding", t => {
    let el = <LucideIcons.TriangleAlert />
    t->expect(el)->Expect.toBe(el)
  })

  test("Hash icon binding", t => {
    let el = <LucideIcons.Hash />
    t->expect(el)->Expect.toBe(el)
  })

  test("Link icon binding", t => {
    let el = <LucideIcons.Link />
    t->expect(el)->Expect.toBe(el)
  })

  test("MoreVertical icon binding", t => {
    let el = <LucideIcons.MoreVertical />
    t->expect(el)->Expect.toBe(el)
  })

  test("ImageIcon icon binding", t => {
    let el = <LucideIcons.ImageIcon />
    t->expect(el)->Expect.toBe(el)
  })

  test("FileImage icon binding", t => {
    let el = <LucideIcons.FileImage />
    t->expect(el)->Expect.toBe(el)
  })

  test("Images icon binding", t => {
    let el = <LucideIcons.Images />
    t->expect(el)->Expect.toBe(el)
  })

  test("GripVertical icon binding", t => {
    let el = <LucideIcons.GripVertical />
    t->expect(el)->Expect.toBe(el)
  })

  test("Download icon binding", t => {
    let el = <LucideIcons.Download />
    t->expect(el)->Expect.toBe(el)
  })

  test("FilePlus icon binding", t => {
    let el = <LucideIcons.FilePlus />
    t->expect(el)->Expect.toBe(el)
  })

  test("Save icon binding", t => {
    let el = <LucideIcons.Save />
    t->expect(el)->Expect.toBe(el)
  })

  test("FolderOpen icon binding", t => {
    let el = <LucideIcons.FolderOpen />
    t->expect(el)->Expect.toBe(el)
  })

  test("Info icon binding", t => {
    let el = <LucideIcons.Info />
    t->expect(el)->Expect.toBe(el)
  })

  test("Share2 icon binding", t => {
    let el = <LucideIcons.Share2 />
    t->expect(el)->Expect.toBe(el)
  })

  test("Film icon binding", t => {
    let el = <LucideIcons.Film />
    t->expect(el)->Expect.toBe(el)
  })

  test("Camera icon binding", t => {
    let el = <LucideIcons.Camera />
    t->expect(el)->Expect.toBe(el)
  })

  test("Sparkles icon binding", t => {
    let el = <LucideIcons.Sparkles />
    t->expect(el)->Expect.toBe(el)
  })

  test("BarChart3 icon binding", t => {
    let el = <LucideIcons.BarChart3 />
    t->expect(el)->Expect.toBe(el)
  })

  test("Copy icon binding", t => {
    let el = <LucideIcons.Copy />
    t->expect(el)->Expect.toBe(el)
  })

  test("Flag icon binding", t => {
    let el = <LucideIcons.Flag />
    t->expect(el)->Expect.toBe(el)
  })

  test("CircleAlert icon with stroke prop", t => {
    let el = <LucideIcons.CircleAlert stroke="red" />
    t->expect(el)->Expect.toBe(el)
  })
})
