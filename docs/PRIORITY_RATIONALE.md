# Task Prioritization Rationale

## Overview
Tasks have been renumbered to prioritize the most critical and foundational modules first. Lower numbers = higher priority.

---

## 🔴 **TIER 1: Core Architecture (147-151)**

### **147 - RootReducer** ⭐ HIGHEST PRIORITY
- **Why First**: Central orchestrator that combines all domain reducers
- **Impact**: Failure here affects the entire state management system
- **Complexity**: Medium (49 lines, but critical logic)
- **Dependencies**: All other reducers depend on this working correctly

### **148 - EventBus** ⭐ CRITICAL
- **Why Second**: Core communication system for the entire application
- **Impact**: Used by navigation, modals, notifications, and scene transitions
- **Complexity**: Medium (63 lines, pub/sub pattern)
- **Dependencies**: Many systems rely on this for decoupled communication

### **149 - NavigationReducer**
- **Why Third**: Handles navigation state, crucial for user experience
- **Impact**: Core feature - users navigate between scenes
- **Complexity**: Medium-High (state transitions)
- **Dependencies**: Used by RootReducer, affects simulation systems

### **150 - ProjectReducer**
- **Why Fourth**: Manages project-level state and metadata
- **Impact**: Affects project loading, saving, and overall structure
- **Complexity**: Medium (domain-specific logic)
- **Dependencies**: Used by RootReducer

### **151 - TimelineReducer**
- **Why Fifth**: Manages timeline/history state
- **Impact**: Important for undo/redo and state tracking
- **Complexity**: Medium (temporal logic)
- **Dependencies**: Used by RootReducer

---

## 🟡 **TIER 2: Systems & Rendering (152-157)**

### **152 - NavigationRenderer**
- **Why Sixth**: Renders navigation UI elements
- **Impact**: Visual feedback for navigation
- **Complexity**: Medium (rendering logic)

### **153 - SimulationNavigation**
- **Why Seventh**: Core simulation system for automated tours
- **Impact**: Key feature for demo/preview functionality
- **Complexity**: High (complex navigation logic)

### **154 - SimulationPathGenerator**
- **Why Eighth**: Generates paths for simulations
- **Impact**: Required for simulation feature
- **Complexity**: High (pathfinding algorithms)

### **155 - TeaserPathfinder**
- **Why Ninth**: Pathfinding for teaser videos
- **Impact**: Marketing/preview feature
- **Complexity**: Medium-High

### **156 - SimulationChainSkipper**
- **Why Tenth**: Optimization for simulation chains
- **Impact**: Performance enhancement
- **Complexity**: Medium

### **157 - ServerTeaser**
- **Why Eleventh**: Server-side teaser generation
- **Impact**: Feature-specific, not core
- **Complexity**: Medium

---

## 🟢 **TIER 3: Utilities & Simple Modules (158-160)**

### **158 - TourTemplates**
- **Why Twelfth**: Template management
- **Impact**: Convenience feature
- **Complexity**: Low-Medium (data structures)

### **159 - Constants**
- **Why Thirteenth**: Application constants
- **Impact**: Low (simple data, no complex logic)
- **Complexity**: Very Low (242 lines of mostly static data)
- **Testing Value**: Minimal - mostly verifies values exist

### **160 - Version**
- **Why Last**: Version utilities
- **Impact**: Very Low (display-only)
- **Complexity**: Trivial (23 lines, 3 simple getters)
- **Testing Value**: Minimal - trivial functions

---

## 📊 **Priority Factors Considered**

1. **Architectural Importance**: Core vs. peripheral systems
2. **Dependency Chain**: What other modules depend on this?
3. **User Impact**: How critical is this to user experience?
4. **Complexity**: More complex = higher risk = higher priority
5. **Testing ROI**: Will tests catch meaningful bugs?

---

## 🎯 **Recommended Approach**

Start with **Task 147 (RootReducer)** and work sequentially. Each task builds confidence in increasingly peripheral systems.

**Time Estimate**:
- Tier 1 (147-151): ~2-3 hours total
- Tier 2 (152-157): ~3-4 hours total  
- Tier 3 (158-160): ~30 minutes total

**Total**: ~6-7.5 hours for complete test coverage

---

## 📝 **Notes**

- Tasks were renumbered on: 2026-01-16
- Original numbering was sequential by creation time
- New numbering reflects strategic priority
- All tasks remain in `tasks/pending` until activated
