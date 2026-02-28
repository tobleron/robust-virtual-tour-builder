let maxLen = 127

type composed = {
  showRent: bool,
  showSale: bool,
  body: string,
  full: string,
}

let normalize = (value: string): string =>
  value
  ->String.trim
  ->String.replaceRegExp(/\\s+/g, " ")
  ->String.trim

let compose = (
  ~comment: string,
  ~phone1: string,
  ~phone2: string,
  ~forRent: bool,
  ~forSale: bool,
): composed => {
  let cleanComment = normalize(comment)
  let p1 = normalize(phone1)
  let p2 = normalize(phone2)
  let numbersPart = if p1 != "" && p2 != "" {
    p1 ++ " / " ++ p2
  } else if p1 != "" {
    p1
  } else if p2 != "" {
    p2
  } else {
    ""
  }
  let body =
    [cleanComment, numbersPart]
    ->Belt.Array.keep(part => part != "")
    ->(parts => Belt.Array.joinWith(parts, " ", part => part))
  let prefixTokens = [
    if forRent {
      Some("RENT")
    } else {
      None
    },
    if forSale {
      Some("SALE")
    } else {
      None
    },
  ]->Belt.Array.keepMap(x => x)
  let prefixText = Belt.Array.joinWith(prefixTokens, " ", x => x)
  let full = if prefixText != "" && body != "" {
    prefixText ++ " " ++ body
  } else if prefixText != "" {
    prefixText
  } else {
    body
  }
  {showRent: forRent, showSale: forSale, body, full}
}

let isWithinLimit = (
  ~comment: string,
  ~phone1: string,
  ~phone2: string,
  ~forRent: bool,
  ~forSale: bool,
): bool => compose(~comment, ~phone1, ~phone2, ~forRent, ~forSale).full->String.length <= maxLen
