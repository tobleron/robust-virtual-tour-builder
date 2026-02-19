/* src/utils/NetworkStatus.resi */

let isOnline: unit => bool
let probe: unit => Promise.t<bool>
let subscribe: (bool => unit) => unit => unit
let forceStatus: bool => unit
let skipProbe: ref<bool>
let initialize: unit => unit
let cleanup: unit => unit
