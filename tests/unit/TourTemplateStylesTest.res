open ReBindings
open TourTemplateStyles

let run = () => {
  Console.log("Running TourTemplateStyles tests...")
  let css = generateCSS("scene1.webp", false, "4k", 32, 100)
  assert(String.includes(css, "scene1.webp"))
  assert(String.includes(css, "1024px")) // 4k desktop max width
  Console.log("✓ TourTemplateStyles: generateCSS verified")
}
