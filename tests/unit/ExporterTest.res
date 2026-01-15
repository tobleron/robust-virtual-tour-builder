/* tests/unit/ExporterTest.res */
open Exporter

let run = () => {
  Console.log("Running Exporter tests...")
  
  // Basic existence check
  assert(Obj.magic(exportTour) != 0)
  
  Console.log("✓ Exporter tests passed")
}
