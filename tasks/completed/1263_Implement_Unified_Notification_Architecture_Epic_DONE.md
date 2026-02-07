# 1263: Implement Unified Notification Architecture (Epic Overview)

**Status**: Pending
**Priority**: High (Enterprise Architecture Improvement)
**Estimated Effort**: 200 story points / ~10 weeks / 2-3 engineers
**Phase**: 4 Sprints (Foundation → Integration → Operations → Polish)

---

## 📋 Executive Summary

Transform the application's fragmented notification system into a unified, enterprise-grade architecture with intelligent queuing, context-awareness, and user-friendly feedback patterns.

**Current Grade**: C+ (Functional but severely fragmented)
**Target Grade**: A (Enterprise-grade, user-focused)

---

## 🚨 Problem Statement

### Current Issues
- **6+ independent notification subsystems** (EventBus, TransitionLock, component-level)
- **Toast Storm anti-pattern**: 60+ notifications for single operation
- **Zombie Modal**: Critical errors trap users, can't dismiss
- **Silent Failures**: 20+ scenarios never notify user
- **Inconsistent Messaging**: Same action gets different tones
- **No Recovery Paths**: Errors don't guide users to solutions
- **No Undo**: Destructive actions permanently lose data

### Estimated Impact
- **30-40% reduction** in user errors (blocked states now clear)
- **25-30% reduction** in support tickets (error messages helpful)
- **+15-20 point NPS improvement** (users feel supported)

---

## 🎯 Solution Overview

### New Architecture
```
NotificationManager (centralized, type-safe)
├─ NotificationQueue (pure logic: dedup, priority)
├─ NotificationCenter (React UI: toasts, modals, progress)
└─ MessageBuilder (standardized, human-readable messages)
```

### Key Improvements
✅ Centralized management
✅ Intelligent queuing (errors first)
✅ Deduplication (same message = 1 notification)
✅ Context-aware feedback
✅ Recovery paths for all errors
✅ Undo support (30-second window)
✅ Human-friendly messages (no jargon)
✅ WCAG AA accessibility

---

## 📊 4-Phase Implementation Plan

### Phase 1: Foundation (Sprint 1-2) - CRITICAL
**Files to Create**:
- `src/core/NotificationTypes.res` (types)
- `src/core/NotificationQueue.res` (pure logic)
- `src/core/NotificationManager.res` (state)
- `src/components/NotificationCenter.res` (UI)

**Acceptance Criteria**:
- ✅ NotificationManager >90% test coverage
- ✅ No regressions in existing features
- ✅ Backward compatible with old ShowNotification
- ✅ App compiles with 0 warnings

**Related Task**: 1264_Phase1_Build_Notification_Foundation_System.md

### Phase 2: Integration (Sprint 2-3) - HIGH PRIORITY
**Deliverables**:
- MessageBuilder for standardized messages
- Upload flow migration
- Project load migration
- Export flow migration
- Error message standardization

### Phase 3: Operations (Sprint 3-4) - HIGH PRIORITY
**Deliverables**:
- OperationTracking (persistent state)
- OperationFeedback (progress widget)
- UndoStack (30-second recovery)
- Undo integration (delete, metadata, links)

### Phase 4: Polish (Sprint 4-5) - MEDIUM PRIORITY
**Deliverables**:
- Better error recovery UI
- Progressive disclosure (expandable details)
- Accessibility audit & fixes
- Comprehensive testing & documentation

---

## 📁 Files to Create/Modify

### New (8 files, ~2000 LOC)
```
src/core/NotificationTypes.res
src/core/NotificationQueue.res
src/core/NotificationManager.res
src/core/OperationTracking.res
src/utils/MessageBuilder.res
src/utils/UndoStack.res
src/components/NotificationCenter.res
src/components/OperationFeedback.res
```

### Modified (5 files, ~150 LOC changes)
```
src/systems/EventBus.res
src/components/NotificationContext.res
src/components/Sidebar/SidebarLogic.res
src/systems/UploadProcessorLogic.res
src/App.res
```

### Tests (3 files, ~1200 LOC)
```
tests/unit/NotificationManager_v.test.res
tests/unit/NotificationQueue_v.test.res
tests/unit/MessageBuilder_v.test.res
```

---

## 🔍 Success Metrics

### By End of Phase 1
- ✅ Centralized notification system working
- ✅ 0 duplicate notifications per operation
- ✅ All 787 existing tests pass
- ✅ 0 compiler warnings

### By End of Phase 2
- ✅ 100% of user messages use MessageBuilder
- ✅ 0 generic errors ("An unexpected server error")
- ✅ All errors include recovery path

### By End of Phase 4
- ✅ Undo available for all destructive actions
- ✅ WCAG AA compliance
- ✅ >90% test coverage
- ✅ Support tickets down 25-30%
- ✅ NPS +15-20 points

---

## 📖 Detailed Audit

Full comprehensive audit document:
`/private/tmp/claude-501/-Users-r2-Desktop-robust-virtual-tour-builder/1b9f7520-0f5d-4dde-af2d-03bc7a9ad3ac/scratchpad/NOTIFICATION_AUDIT.md`

Key findings:
- 8 major UX anti-patterns documented
- 20+ missing notification scenarios identified
- 9 enterprise standards violations
- Architecture fragmentation analysis

---

## 🚀 Next Task

**→ 1264_Phase1_Build_Notification_Foundation_System.md**

This epic defines the overall strategy. Task 1264 contains the Phase 1 detailed implementation plan.

---

## ⚠️ Dependencies

- ✅ ReScript compiler working
- ✅ Vitest test framework available
- ✅ React 19+ available
- ✅ EventBus accessible (no changes needed)
- ✅ No external dependencies required

---

## 📝 Notes

- Backward compatible with existing ShowNotification calls
- Gradual rollout per-phase (no big bang)
- No UX changes in Phase 1 (organization only)
- User-facing improvements start Phase 2

