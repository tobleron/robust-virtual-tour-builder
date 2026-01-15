/* tests/unit/DownloadSystemTest.res */
open DownloadSystem

let run = () => {
  Console.log("Running DownloadSystem tests...")
  
  // Test: getExtension
  assert(getExtension("test.jpg") == ".jpg")
  assert(getExtension("TEST.PNG") == ".png")
  assert(getExtension("no_ext") == ".dat")
  
  Console.log("✓ DownloadSystem tests passed")
}
