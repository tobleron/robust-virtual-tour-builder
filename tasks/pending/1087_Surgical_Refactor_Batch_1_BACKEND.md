# Task 1087: Surgical Refactor Batch 1 BACKEND

## Objective
### 📚 Complexity Legend
* **Nesting:** Nesting depth penalty (Weight: 0.15).
* **Density:** Logic density (branching/loops) (Weight: 2.00).
* **Deps:** External dependency pressure.

### 🎯 General Instruction
Reduce the complexity variables for the following files to reach a Drag factor below 2.00. 
You have full architectural autonomy on how to split, extract, or simplify the code to achieve this goal while maintaining logic integrity.

## Tasks
- [ ] **../../backend/src/middleware/quota_check.rs** - [Nesting: 0.60, Density: 0.06, Deps: 0.00] | Drag: 2.66 | LOC: 127/94
- [ ] **../../backend/src/middleware/auth.rs** - [Nesting: 0.90, Density: 0.13, Deps: 0.00] | Drag: 4.03 | LOC: 155/51
- [ ] **../../backend/src/models.rs** - [Nesting: 0.15, Density: 0.02, Deps: 0.00] | Drag: 3.67 | LOC: 520/80
- [ ] **../../backend/src/main.rs** - [Nesting: 0.60, Density: 0.04, Deps: 0.00] | Drag: 3.14 | LOC: 285/54
- [ ] **../../backend/src/api/telemetry.rs** - [Nesting: 0.60, Density: 0.12, Deps: 0.00] | Drag: 2.22 | LOC: 154/124
- [ ] **../../backend/src/api/project.rs** - [Nesting: 1.05, Density: 0.13, Deps: 0.00] | Drag: 7.18 | LOC: 518/30
- [ ] **../../backend/src/api/media/image.rs** - [Nesting: 0.75, Density: 0.07, Deps: 0.00] | Drag: 6.32 | LOC: 482/30
- [ ] **../../backend/src/api/media/video.rs** - [Nesting: 0.75, Density: 0.11, Deps: 0.00] | Drag: 4.46 | LOC: 372/43
- [ ] **../../backend/src/services/shutdown.rs** - [Nesting: 0.75, Density: 0.15, Deps: 0.00] | Drag: 2.70 | LOC: 162/93
- [ ] **../../backend/src/services/auth/jwt.rs** - [Nesting: 0.30, Density: 0.00, Deps: 0.00] | Drag: 3.30 | LOC: 69/68
- [ ] **../../backend/src/services/geocoding/mod.rs** - [Nesting: 0.45, Density: 0.06, Deps: 0.00] | Drag: 2.51 | LOC: 246/75
- [ ] **../../backend/src/services/upload_quota.rs** - [Nesting: 0.45, Density: 0.06, Deps: 0.00] | Drag: 3.01 | LOC: 298/57
- [ ] **../../backend/src/services/project/package.rs** - [Nesting: 0.75, Density: 0.10, Deps: 0.00] | Drag: 2.35 | LOC: 137/83
- [ ] **../../backend/src/services/project/load.rs** - [Nesting: 0.60, Density: 0.06, Deps: 0.00] | Drag: 3.66 | LOC: 155/42
- [ ] **../../backend/src/services/project/validate.rs** - [Nesting: 0.90, Density: 0.17, Deps: 0.00] | Drag: 2.07 | LOC: 197/100
- [ ] **../../backend/src/services/media/analysis/quality.rs** - [Nesting: 0.60, Density: 0.18, Deps: 0.00] | Drag: 1.78 | LOC: 220/126
- [ ] **../../backend/src/services/media/analysis/exif.rs** - [Nesting: 0.75, Density: 0.14, Deps: 0.00] | Drag: 2.89 | LOC: 117/84
- [ ] **../../backend/src/services/media/naming.rs** - [Nesting: 0.30, Density: 0.07, Deps: 0.00] | Drag: 3.87 | LOC: 109/39
