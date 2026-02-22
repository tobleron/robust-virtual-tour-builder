type teaserStyle =
  | Cinematic
  | FastShots
  | SimpleCrossfade

type styleOption = {
  id: string,
  label: string,
  description: string,
  available: bool,
}

let defaultStyle = Cinematic

let toString = (style: teaserStyle): string =>
  switch style {
  | Cinematic => "cinematic"
  | FastShots => "fast_shots"
  | SimpleCrossfade => "simple_crossfade"
  }

let fromString = (raw: string): teaserStyle =>
  switch raw {
  | "fast_shots" => FastShots
  | "simple_crossfade" => SimpleCrossfade
  | _ => Cinematic
  }

let options: array<styleOption> = [
  {
    id: toString(Cinematic),
    label: "Cinematic",
    description: "Full deterministic motion parity with simulation dynamics.",
    available: true,
  },
  {
    id: toString(FastShots),
    label: "Fast Shots",
    description: "Rapid punch-in sequence style (planned).",
    available: false,
  },
  {
    id: toString(SimpleCrossfade),
    label: "Simple Crossfade",
    description: "Simple scene-to-scene dissolve teaser style (planned).",
    available: false,
  },
]

let isAvailable = (style: teaserStyle): bool =>
  switch style {
  | Cinematic => true
  | FastShots | SimpleCrossfade => false
  }

let label = (style: teaserStyle): string =>
  options
  ->Belt.Array.getBy(opt => fromString(opt.id) == style)
  ->Option.map(opt => opt.label)
  ->Option.getOr("Cinematic")
