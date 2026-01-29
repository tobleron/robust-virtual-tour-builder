# Task 1084: Merge Folders BACKEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 1.00 Score (approx 800 LOC).
**Action:** Move the following files into a single cohesive module.

## Tasks
## Tasks
- [ ] **Middleware**: Merge `../../backend/src/middleware/*.rs` (`mod.rs`, `auth.rs`, `quota_check.rs`, `request_tracker.rs`) into `../../backend/src/middleware.rs`.
- [ ] **Media Analysis**: Merge `../../backend/src/services/media/analysis/*.rs` (`mod.rs`, `exif.rs`, `quality.rs`) into `../../backend/src/services/media/analysis.rs`.
- [ ] **Geocoding**: Merge `../../backend/src/services/geocoding/*.rs` (`mod.rs`, `logic.rs`) into `../../backend/src/services/geocoding.rs`.
- [ ] **Auth Service**: Merge `../../backend/src/services/auth/*.rs` (`mod.rs`, `jwt.rs`) into `../../backend/src/services/auth.rs`.
- [ ] **Media Service**: Merge `../../backend/src/services/media/*.rs` (`mod.rs`, `storage.rs`, `naming.rs`, `naming_old.rs`, `webp.rs`, `resizing.rs`) into `../../backend/src/services/media.rs`.
- [ ] **Project Service**: Merge `../../backend/src/services/project/*.rs` (`mod.rs`, `load.rs`, `validate.rs`, `package.rs`) into `../../backend/src/services/project.rs`.
- [ ] **Core Services**: Merge `../../backend/src/services/*.rs` (`mod.rs`, `database.rs`, `upload_quota.rs`, `shutdown.rs`) into `../../backend/src/services.rs`.
- [ ] Folder: `../../backend/src/middleware` - Read Tax high (Score 4.00).
    - `request_tracker.rs`
    - `quota_check.rs`
    - `auth.rs`
    - `mod.rs`
- [ ] Folder: `../../backend/src/services/media/analysis` - Read Tax high (Score 3.00).
    - `mod.rs`
    - `exif.rs`
    - `quality.rs`
- [ ] Folder: `../../backend/src/services/geocoding` - Read Tax high (Score 2.00).
    - `mod.rs`
    - `logic.rs`
- [ ] Folder: `../../backend/src/services` - Read Tax high (Score 5.00).
    - `upload_quota_tests.rs`
    - `upload_quota.rs`
    - `database.rs`
    - `mod.rs`
    - `shutdown.rs`
- [ ] Folder: `../../backend/src/services/project` - Read Tax high (Score 2.00).
    - `mod.rs`
    - `package.rs`
    - `load.rs`
    - `validate.rs`
- [ ] Folder: `../../backend/src/services/auth` - Read Tax high (Score 2.00).
    - `jwt.rs`
    - `mod.rs`
- [ ] Folder: `../../backend/src/services/media` - Read Tax high (Score 6.00).
    - `naming.rs`
    - `storage.rs`
    - `naming_old.rs`
    - `resizing.rs`
    - `mod.rs`
    - `webp.rs`
- [ ] Folder: `../../backend/src/services/project` - Read Tax high (Score 2.00).
    - `mod.rs`
    - `validate.rs`
    - `package.rs`
    - `load.rs`
- [ ] Folder: `../../backend/src/services/media/analysis` - Read Tax high (Score 3.00).
    - `quality.rs`
    - `exif.rs`
    - `mod.rs`
- [ ] Folder: `../../backend/src/services/media` - Read Tax high (Score 6.00).
    - `resizing.rs`
    - `webp.rs`
    - `naming_old.rs`
    - `naming.rs`
    - `mod.rs`
    - `storage.rs`
- [ ] Folder: `../../backend/src/services` - Read Tax high (Score 5.00).
    - `database.rs`
    - `mod.rs`
    - `upload_quota_tests.rs`
    - `upload_quota.rs`
    - `shutdown.rs`
