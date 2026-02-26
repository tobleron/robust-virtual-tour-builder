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
    description: "Static endpoint scene shots, stitched into a deterministic teaser.",
    available: true,
  },
  {
    id: toString(SimpleCrossfade),
    label: "Simple Crossfade",
    description: "Static endpoint shots with short premium dissolves.",
    available: true,
  },
]

let isAvailable = (style: teaserStyle): bool =>
  switch style {
  | Cinematic | FastShots | SimpleCrossfade => true
  }

let label = (style: teaserStyle): string =>
  options
  ->Belt.Array.getBy(opt => fromString(opt.id) == style)
  ->Option.map(opt => opt.label)
  ->Option.getOr("Cinematic")
