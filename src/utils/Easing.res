/* src/utils/Easing.res */

/**
 * Premium Easing functions for navigation and animations.
 * Quintic easing provides a very soft start and end, giving a "weighted" cinematic feel.
 */
/**
 * Quintic Ease-In-Out
 * t: linear progress (0.0 to 1.0)
 */
let easeInOutQuint = (t: float): float => {
  t < 0.5 ? 16.0 *. t *. t *. t *. t *. t : 1.0 -. Math.pow(-2.0 *. t +. 2.0, ~exp=5.0) /. 2.0
}

/**
 * Quartic Ease-In-Out
 * Slightly more "snappy" than quintic but still very smooth.
 */
let easeInOutQuart = (t: float): float => {
  t < 0.5 ? 8.0 *. t *. t *. t *. t : 1.0 -. Math.pow(-2.0 *. t +. 2.0, ~exp=4.0) /. 2.0
}

/**
 * Cubic Ease-In-Out
 * Standard smooth easing.
 */
let easeInOutCubic = (t: float): float => {
  t < 0.5 ? 4.0 *. t *. t *. t : 1.0 -. Math.pow(-2.0 *. t +. 2.0, ~exp=3.0) /. 2.0
}

/**
 * Trapezoidal Easing
 * explicitly defines the "ramp up" and "ramp down" duration ratios.
 * factor: The percentage of time spent accelerating (and decelerating).
 * e.g. 0.12 means 12% accel, 76% cruise, 12% decel.
 */
let trapezoidal = (t: float, factor: float): float => {
  let vmax = 1.0 /. (1.0 -. factor)
  if t < factor {
    0.5 *. (vmax /. factor) *. t *. t
  } else if t > 1.0 -. factor {
    1.0 -. 0.5 *. (vmax /. factor) *. (1.0 -. t) *. (1.0 -. t)
  } else {
    vmax *. (t -. 0.5 *. factor)
  }
}
