# Task 1222: Complete E2E Critical Path Coverage

## 🚨 Trigger
Commercial Readiness Audit identified insufficient E2E test coverage as **P0 Critical Gap**.

## 📊 Current Status
- **Current E2E Coverage**: ~80% (25 tests)
- **Target E2E Coverage**: 80% (25+ tests)
- **Tests Completed**: 25/25
- **Tests Remaining**: 0
- **Phase 1 (P0)**: ✅ **COMPLETE**
- **Phase 2 (P1)**: ✅ **COMPLETE**
- **Phase 3 (P2)**: ✅ **COMPLETE** (Suite 5 added)

## 🎯 Objective
Add comprehensive E2E tests for the remaining critical user journeys to achieve 80% coverage and meet commercial readiness standards.

## 📋 Required Test Suites

### **Suite 1: Full Workflow (Upload → Link → Export)** ✅
**Priority**: P0 (Blocking)  
**Estimated Time**: 2 hours

**Tests to Add**:
1. `upload-link-export-workflow.spec.ts`:
   - Upload 3 panoramic images
   - Verify scenes created successfully
   - Add hotspots linking scenes
   - Verify hotspot connections
   - Export project as ZIP
   - Verify ZIP contains all assets
   - Verify exported HTML is valid

**Success Criteria**:
- Full workflow completes without errors
- Exported tour is playable standalone
- All assets are included in export

---

### **Suite 2: Project Persistence (Save → Load Round-Trip)** ✅
**Priority**: P0 (Blocking)  
**Estimated Time**: 1.5 hours

**Tests to Add**:
2. `save-load-recovery.spec.ts`:
   - Create project with 5 scenes
   - Add hotspots and labels
   - Save project to backend
   - Clear browser state (localStorage, IndexedDB)
   - Load project from backend
   - Verify all scenes restored
   - Verify all hotspots restored
   - Verify all labels restored

**Success Criteria**:
- Project state perfectly restored after load
- No data loss during save/load cycle
- Recovery modal appears if interrupted

---

### **Suite 3: Simulation & Teaser** ✅
**Priority**: P1 (High)  
**Estimated Time**: 2 hours

**Tests to Add**:
3. `simulation-teaser.spec.ts`:
   - Create tour with 10 linked scenes
   - Start autopilot simulation
   - Verify simulation navigates through scenes
   - Pause/resume simulation
   - Start teaser recording
   - Verify recording starts
   - Stop recording
   - Verify video file generated

**Success Criteria**:
- Simulation completes full tour
- Teaser video is downloadable
- Video contains scene transitions

---

### **Suite 4: Error Recovery Scenarios** ✅
**Priority**: P1 (High)  
**Estimated Time**: 1.5 hours

**Tests to Add**:
4. `error-recovery.spec.ts`:
   - **Test 4.1**: Network failure during upload
     - Mock network error mid-upload
     - Verify retry logic activates
     - Verify upload completes after retry
   
   - **Test 4.2**: IndexedDB quota exceeded
     - Fill IndexedDB to quota limit
     - Attempt to save project
     - Verify quota warning appears
     - Verify "Clear Old Projects" option shown
   
   - **Test 4.3**: Invalid JSON in project file
     - Load project with malformed JSON
     - Verify error message shown
     - Verify app doesn't crash
   
   - **Test 4.4**: Browser refresh during save
     - Start save operation
     - Refresh browser mid-save
     - Verify recovery modal appears
     - Verify operation can be resumed or dismissed

**Success Criteria**:
- All error scenarios handled gracefully
- User receives clear error messages
- No data loss during errors
- App remains stable after errors

---

### **Suite 5: Performance & Load Testing** ✅
**Priority**: P2 (Medium)  
**Estimated Time**: 1 hour

**Tests to Add**:
5. `performance.spec.ts`:
   - **Test 5.1**: Large project (200 scenes)
     - Load project with 200 scenes
     - Verify UI remains responsive
     - Measure load time (<10s)
   
   - **Test 5.2**: Memory leak detection
     - Navigate through 50 scenes
     - Measure memory usage
     - Verify no memory leaks
   
   - **Test 5.3**: Bundle size validation
     - Verify initial bundle <300KB gzipped
     - Verify lazy-loaded chunks <100KB each

**Success Criteria**:
- App handles 200+ scenes without lag
- Memory usage stays under 500MB
- Bundle size within targets

---

## 📁 Implementation Plan

### **Phase 1: Critical Workflows (P0)** - 3.5 hours
1. Create `tests/e2e/upload-link-export-workflow.spec.ts`
2. Create `tests/e2e/save-load-recovery.spec.ts`
3. Run tests and verify all pass
4. Update audit documents with new coverage metrics

### **Phase 2: Advanced Features (P1)** - 3.5 hours
5. Create `tests/e2e/simulation-teaser.spec.ts`
6. Create `tests/e2e/error-recovery.spec.ts`
7. Run tests and verify all pass
8. Update audit documents

### **Phase 3: Performance (P2)** - 1 hour
9. Create `tests/e2e/performance.spec.ts`
10. Add performance budgets to CI
11. Run tests and verify all pass

**Total Estimated Time**: 8 hours

---

## ✅ Acceptance Criteria

### **Test Coverage**:
- [ ] E2E test count: 25+ tests
- [ ] E2E coverage: 80%+ of critical paths
- [ ] All P0 workflows tested
- [ ] All error scenarios tested

### **Test Quality**:
- [ ] All tests pass consistently (3 consecutive runs)
- [ ] Tests use AI-observable logging
- [ ] Tests capture screenshots/videos on failure
- [ ] Tests have clear, descriptive names

### **Documentation**:
- [ ] Update `docs/COMMERCIAL_READINESS_AUDIT.md` with new metrics
- [ ] Update `docs/AUDIT_EXECUTIVE_SUMMARY.md`
- [ ] Update `README.md` test coverage section
- [ ] Add test documentation in `tests/e2e/README.md`

### **CI Integration**:
- [ ] Tests run in CI pipeline
- [ ] Performance budgets enforced
- [ ] Test failures block merges

---

## 📊 Success Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| E2E Test Count | 25 | 25+ | ✅ 100% |
| E2E Coverage | 80% | 80% | ✅ 100% |
| Critical Paths Tested | 10 | 10 | ✅ 100% |
| Commercial Grade Score | 9.2/10 | 9.0/10 | ✅ 102% |

---

## 🔗 Related Documents
- **Audit Report**: `docs/COMMERCIAL_READINESS_AUDIT.md`
- **Executive Summary**: `docs/AUDIT_EXECUTIVE_SUMMARY.md`
- **Existing Tests**: `tests/e2e/robustness.spec.ts`
- **Test Standards**: `.agent/workflows/testing-standards.md`

---

## 📝 Notes

### **Why This Matters**:
The Commercial Readiness Audit identified E2E test coverage as the **#1 critical gap** preventing commercial release. Completing this task will:
- Increase confidence in production deployments
- Catch regressions before they reach users
- Validate critical user journeys
- Improve commercial readiness score from 8.0 to 9.0

### **Test Data**:
- Use `tests/fixtures/sample-tour.zip` for consistent test data
- Generate test panoramas programmatically if needed
- Mock backend responses for deterministic tests

### **Performance Considerations**:
- Run performance tests in separate CI job
- Use headless browsers for speed
- Parallelize test execution across browsers

---

**Created**: 2026-02-04  
**Priority**: P0 (Blocking for commercial release)  
**Estimated Effort**: 8 hours  
**Dependencies**: None  
**Assigned To**: Development Team
