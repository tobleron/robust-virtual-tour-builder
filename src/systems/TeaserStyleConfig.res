type teaserConfig = {clipDuration: float, transitionDuration: float, cameraPanOffset: float}

let standardConfig = {clipDuration: 2500.0, transitionDuration: 1000.0, cameraPanOffset: 20.0}
let slowConfig = {clipDuration: 4000.0, transitionDuration: 1500.0, cameraPanOffset: 30.0}
let punchyConfig = {clipDuration: 1800.0, transitionDuration: 600.0, cameraPanOffset: 0.0}

let getConfigForStyle = (style: string) => {
  switch style {
  | "punchy" => punchyConfig
  | "slow" => slowConfig
  | "cinematic" => slowConfig
  | _ => standardConfig
  }
}
