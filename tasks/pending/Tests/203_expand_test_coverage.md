# Expand Test Coverage for Critical Functions

## Overview
Current test coverage is insufficient, with many critical functions having minimal or placeholder tests. ProjectManager and Exporter have especially poor coverage. This task adds comprehensive tests including error paths, edge cases, and integration scenarios.

## Current Test Gaps
- ProjectManagerTest.res: Only logs "Module loaded"
- ExporterTest.res: Only checks function existence via Obj.magic
- No error path testing for Result-returning functions
- Missing edge case and integration tests
- No validation of error message content

## Implementation Steps

### 1. Enhance ProjectManager Tests
Update `tests/unit/ProjectManagerTest.res`:

```rescript
let run = () => {
  Console.log("Running ProjectManager tests...")

  // Test validateProjectStructure - Success Path
  let validProject = {
    name: "Test Project",
    scenes: [{
      id: "scene1",
      name: "Scene 1",
      file: {name: "scene1.jpg", size: 1000, type_: "image/jpeg"},
      hotspots: [],
      category: "room",
      floor: "1st",
      label: "Living Room",
      isAutoForward: false,
    }],
  }

  switch ProjectManager.validateProjectStructure(validProject) {
  | Ok(validated) => Console.log("✓ Valid project structure test passed")
  | Error(msg) => Console.log("✗ Valid project should pass: " ++ msg)
  }

  // Test validateProjectStructure - Missing Scenes
  let invalidProjectNoScenes = {
    name: "Test Project",
    // scenes missing
  }

  switch ProjectManager.validateProjectStructure(invalidProjectNoScenes) {
  | Ok(_) => Console.log("✗ Project without scenes should fail")
  | Error(msg) => Console.log("✓ Missing scenes correctly rejected: " ++ msg)
  }

  // Test validateProjectStructure - Invalid Scene Data
  let invalidProjectBadScene = {
    name: "Test Project",
    scenes: [{
      // Missing required fields
      name: "Bad Scene"
    }],
  }

  switch ProjectManager.validateProjectStructure(invalidProjectBadScene) {
  | Ok(_) => Console.log("✗ Project with invalid scenes should fail")
  | Error(msg) => Console.log("✓ Invalid scene data correctly rejected: " ++ msg)
  }

  // Test createSavePackage
  let testState = {
    scenes: validProject.scenes,
    activeIndex: 0,
    tourName: "Test Tour",
    // ... other required state fields
  }

  switch ProjectManager.createSavePackage(testState) {
  | Ok(package) => Console.log("✓ Save package creation successful")
  | Error(msg) => Console.log("✗ Save package creation failed: " ++ msg)
  }

  Console.log("ProjectManager tests completed.")
}
```

### 2. Enhance Exporter Tests
Update `tests/unit/ExporterTest.res`:

```rescript
let run = () => {
  Console.log("Running Exporter tests...")

  // Create complete mock state for testing
  let mockState = {
    scenes: [{
      id: "scene1",
      name: "Test Scene",
      file: {name: "scene1.jpg", size: 1000, type_: "image/jpeg"},
      hotspots: [{
        linkId: "link1",
        yaw: 0.0,
        pitch: 0.0,
        target: "scene2",
        targetYaw: Some(1.57),
        targetPitch: Some(0.0),
      }],
      category: "room",
      floor: "ground",
      label: "Entry",
      isAutoForward: false,
    }],
    activeIndex: 0,
    tourName: "Test Virtual Tour",
    // ... other required state fields
  }

  // Test JSON export
  switch Exporter.exportTour(mockState, "json") {
  | Ok(exportData) => {
      Console.log("✓ JSON export successful")
      // Verify structure
      if (Obj.magic(exportData)["scenes"] && Obj.magic(exportData)["name"]) {
        Console.log("✓ JSON export structure correct")
      } else {
        Console.log("✗ JSON export missing required fields")
      }
    }
  | Error(msg) => Console.log("✗ JSON export failed: " ++ msg)
  }

  // Test HTML export
  switch Exporter.exportTour(mockState, "html") {
  | Ok(exportData) => {
      Console.log("✓ HTML export successful")
      let htmlString = Obj.magic(exportData)
      if (String.contains(htmlString, "<!DOCTYPE html>") &&
          String.contains(htmlString, "Test Virtual Tour")) {
        Console.log("✓ HTML export contains expected content")
      } else {
        Console.log("✗ HTML export missing expected content")
      }
    }
  | Error(msg) => Console.log("✗ HTML export failed: " ++ msg)
  }

  // Test export with empty state
  let emptyState = {
    scenes: [],
    activeIndex: -1,
    tourName: "",
    // ... minimal state
  }

  switch Exporter.exportTour(emptyState, "json") {
  | Ok(_) => Console.log("✓ Empty state export handled (should succeed or fail gracefully)")
  | Error(msg) => Console.log("✓ Empty state correctly rejected: " ++ msg)
  }

  Console.log("Exporter tests completed.")
}
```

### 3. Add Error Path Testing Framework
Create helper functions for testing error scenarios:

```rescript
// In test utilities
module TestHelpers = {
  let expectError = (result, expectedSubstring) => {
    switch result {
    | Ok(_) => false // Should have failed
    | Error(msg) => String.contains(msg, expectedSubstring)
    }
  }

  let expectSuccess = (result) => {
    switch result {
    | Ok(_) => true
    | Error(_) => false
    }
  }
}

// Usage in tests
if (TestHelpers.expectError(invalidResult, "missing scenes")) {
  Console.log("✓ Error message contains expected text")
} else {
  Console.log("✗ Error message incorrect")
}
```

### 4. Add Integration Tests
Create new integration test files:

**tests/integration/ProjectWorkflowTest.res:**
```rescript
let run = () => {
  Console.log("Running Project Workflow integration tests...")

  // Test complete project lifecycle
  let initialData = loadTestProjectData()

  // Load -> Validate -> Modify -> Export cycle
  let workflow = ProjectManager.validateProjectStructure(initialData)
    ->Result.flatMap(validated => ProjectManager.createSavePackage(validated))
    ->Result.flatMap(saveData => Exporter.exportTour(saveData, "json"))

  switch workflow {
  | Ok(finalResult) => Console.log("✓ Complete project workflow successful")
  | Error(msg) => Console.log("✗ Project workflow failed: " ++ msg)
  }

  Console.log("Project Workflow integration tests completed.")
}
```

### 5. Add Edge Case Tests
Test boundary conditions and unusual inputs:

```rescript
// Test with maximum scenes
let maxScenesProject = {
  name: "Max Scenes Test",
  scenes: Array.range(0, 999)->Array.map(i => createTestScene(i)),
}

// Test with unicode characters
let unicodeProject = {
  name: "测试项目 🚀",
  scenes: [createUnicodeScene()],
}

// Test with extremely large hotspot arrays
let largeHotspotsScene = {
  // ... normal scene data
  hotspots: Array.range(0, 1000)->Array.map(i => createTestHotspot(i)),
}
```

### 6. Update Test Runner
Enhance TestRunner to verify Result pattern compliance:

```rescript
// Add to TestRunner.res
let verifyResultHandling = (testModule) => {
  // Check that tests properly handle both Ok and Error cases
  // This could be done by analyzing test code or adding metadata
}

// Add coverage reporting
let reportCoverage = () => {
  let totalFunctions = countTotalFunctions()
  let testedFunctions = countTestedFunctions()
  let coverage = (testedFunctions /. totalFunctions) *. 100.0
  Console.log(\`Test coverage: \${coverage->Float.toString}%\`)
}
```

## Testing Requirements
- All public functions must have tests
- Error paths must be tested for all Result-returning functions
- Edge cases (empty inputs, maximum values, unicode) must be covered
- Integration tests for complete workflows
- Test utilities for common assertions

## Completion Criteria
- [ ] ProjectManagerTest.res covers all public functions with success/error paths
- [ ] ExporterTest.res tests all export formats and edge cases
- [ ] All systems have comprehensive test coverage
- [ ] Integration tests added for key workflows
- [ ] Error message content validation added
- [ ] Test coverage reporting implemented
- [ ] All tests pass consistently
- [ ] No untested public functions remain