/* src/utils/ChunkPrefetch.res */

let warmedUrlsRef: ref<array<string>> = ref([])

let warmUrl = (url: string): unit => {
  if !Belt.Array.some(warmedUrlsRef.contents, existing => existing == url) {
    warmedUrlsRef := Belt.Array.concat(warmedUrlsRef.contents, [url])
    let _ = WebApiBindings.Fetch.fetchSimple(url)
  }
}

let warmExporter = () => warmUrl("/static/js/exporter.js")
let warmTeaser = () => warmUrl("/static/js/teaser.js")
let warmSimulation = () => warmUrl("/static/js/simulation.js")
let warmExif = () => warmUrl("/static/js/exif.js")
