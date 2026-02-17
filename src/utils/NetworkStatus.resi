/* src/utils/NetworkStatus.resi */

let isOnline: unit => bool
let subscribe: (bool => unit) => unit => unit
let initialize: unit => unit
let cleanup: unit => unit
