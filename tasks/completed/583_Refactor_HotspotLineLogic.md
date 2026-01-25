# Task 583: Refactor HotspotLineLogic (Math vs Rendering)

## 🚨 Trigger
Project "Surgical Edit" Initiative.
Current file mixes 3D Projection Math with direct SVG DOM manipulation.

## Objective
Strictly separate Pure Math from Impure Rendering.

## Required Refactoring
1. **ProjectionMath.res**: Pure, side-effect free module. Input: 3D Coords, Camera State. Output: 2D Screen Coords.
2. **SvgRenderer.res**: "Dumb" renderer that takes 2D Coords and updates DOM attributes.
3. **HotspotLineLogic.res**: Becomes the coordinator/facade.

## Safety & Constraints
- **Performance**: This runs on \`requestAnimationFrame\`. Do not introduce object allocation in the hot loop.
