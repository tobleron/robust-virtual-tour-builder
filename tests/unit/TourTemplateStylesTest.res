open TourTemplateStyles

let run = () => {
  Console.log("Running TourTemplateStyles tests...")

  // Test generateCSS Desktop 4K
  let css4k = generateCSS("scene1.jpg", false, "4k", 32, 40)
  assert(String.includes(css4k, "scene1.jpg"))
  assert(String.includes(css4k, "max-width: 1024px"))
  assert(String.includes(css4k, "height: 32px"))
  assert(String.includes(css4k, "height: 40px")) // Logo size
  assert(String.includes(css4k, "margin-left: -16px")) // Half size
  Console.log("✓ TourTemplateStyles: generateCSS Desktop 4K verified")

  // Test generateCSS Mobile HD
  let cssMobile = generateCSS("sceneMobile.jpg", true, "hd", 24, 30)
  assert(String.includes(cssMobile, "sceneMobile.jpg"))
  assert(String.includes(cssMobile, "width: 375px")) // Mobile width
  assert(String.includes(cssMobile, "height: 667px")) // Mobile height
  assert(String.includes(cssMobile, "height: 24px")) // Base size
  assert(String.includes(cssMobile, "margin-left: -12px")) // Half size
  Console.log("✓ TourTemplateStyles: generateCSS Mobile HD verified")
}
