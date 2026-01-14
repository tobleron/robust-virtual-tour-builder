# Task: Convert Imperative Loops to Functional Iterators

## Objective
Refactor remaining imperative loops in the Rust backend to use functional iterator chains for better readability and optimization.

## Context
Functional programming prefers declarative iterator chains (`.map()`, `.filter()`, `.fold()`) over imperative `for` loops with mutation. Rust's iterator chains are also zero-cost abstractions that can be better optimized by the compiler.

## Current Imperative Patterns

### 1. Histogram Calculation (lines 579-591)

```rust
// Current - imperative with mutation
for chunk in thumb_rgba.chunks(4) {
    if chunk.len() < 3 { continue; }
    let r = chunk[0] as usize;
    // ...
    hist_r[r] += 1;
    // ...
}
```

### 2. Laplacian Variance Calculation (lines 604-618)

```rust
// Current - nested loops
for y in (y_start + 1)..(y_end - 1) {
    for x in 1..(w - 1) {
        let idx = (y * w + x) as usize;
        // ...
    }
}
```

## Target Implementations

### 1. Histogram with fold()

```rust
let (hist_r, hist_g, hist_b, hist_gray, total_lum, gray_pixels) = 
    thumb_rgba.chunks(4)
        .filter(|chunk| chunk.len() >= 3)
        .fold(
            (vec![0u32; 256], vec![0u32; 256], vec![0u32; 256], 
             vec![0u32; 256], 0u64, Vec::with_capacity((w * h) as usize)),
            |(mut hr, mut hg, mut hb, mut hgray, mut lum, mut grays), chunk| {
                let (r, g, b) = (chunk[0] as usize, chunk[1] as usize, chunk[2] as usize);
                hr[r] += 1;
                hg[g] += 1;
                hb[b] += 1;
                
                let gray = ((chunk[0] as u32 * 54 + chunk[1] as u32 * 183 + chunk[2] as u32 * 19) >> 8) as u8;
                hgray[gray as usize] += 1;
                lum += gray as u64;
                grays.push(gray);
                
                (hr, hg, hb, hgray, lum, grays)
            }
        );
```

Note: In this case, the imperative version may be clearer. Use judgment.

### 2. Laplacian with Iterator

```rust
let (laplace_sum, laplace_sq_sum, sampled_count) = 
    ((y_start + 1)..(y_end - 1))
        .flat_map(|y| (1..(w - 1)).map(move |x| (y, x)))
        .filter_map(|(y, x)| {
            let idx = (y * w + x) as usize;
            if idx >= gray_pixels.len() { return None; }
            
            let center = gray_pixels[idx] as i32;
            let lap = gray_pixels[idx - w as usize] as i32
                + gray_pixels[idx - 1] as i32
                + gray_pixels[idx + 1] as i32
                + gray_pixels[idx + w as usize] as i32
                - 4 * center;
            
            Some(lap as f64)
        })
        .fold((0.0f64, 0.0f64, 0u64), |(sum, sq_sum, count), lap| {
            (sum + lap, sq_sum + lap * lap, count + 1)
        });
```

## When to Apply

| Pattern | Convert? | Reason |
|---------|----------|--------|
| Simple transforms | Yes | Clear intent, better optimization |
| Complex nested logic | Maybe | Readability may suffer |
| Performance critical | Profile first | Sometimes imperative is faster |
| Side effects needed | No | Keep imperative |

## Guidelines

1. **Convert if it improves readability**: If the functional version is clearer, do it.
2. **Keep imperative if complex**: Nested state updates may be clearer imperatively.
3. **Benchmark hot paths**: Profile before and after for critical code.
4. **Document complex chains**: Add comments explaining the transformation.

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/handlers.rs` | Evaluate and refactor where beneficial |

## Testing Checklist

- [ ] Image quality analysis produces same results
- [ ] No performance regression (run benchmarks)
- [ ] Code is more readable or equally clear
- [ ] All tests pass

## Definition of Done

- Identified loops evaluated for conversion
- Clear improvements converted
- Complex/hot-path code left if clearer
- Benchmarks show no regression
