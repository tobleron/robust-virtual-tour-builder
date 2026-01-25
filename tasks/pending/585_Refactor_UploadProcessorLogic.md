# Task 585: Refactor UploadProcessorLogic

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File exceeds 360 line limit (606 lines). Complex image validation and clustering logic.

## Objective
Separate Validation, Fingerprinting, and Clustering.

## Required Refactoring
1. **ImageValidator.res**: Pure validation rules (size, type, dimensions).
2. **FingerprintService.res**: Hashing and duplication detection.
3. **PanoramaClusterer.res**: Grouping logic for scenes.
