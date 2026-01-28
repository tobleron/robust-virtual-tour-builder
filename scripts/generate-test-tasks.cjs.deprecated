const fs = require('fs');
const path = require('path');

const tasks = [
  { id: '026', name: 'ColorPalette', file: 'src/utils/ColorPalette.res' },
  { id: '027', name: 'NavigationUI', file: 'src/systems/NavigationUI.res' },
  { id: '028', name: 'ViewerState', file: 'src/components/ViewerState.res' },
  { id: '029', name: 'Sidebar', file: 'src/components/Sidebar.res' },
  { id: '030', name: 'UploadReport', file: 'src/components/UploadReport.res' },
  { id: '031', name: 'LinkModal', file: 'src/components/LinkModal.res' },
  { id: '032', name: 'ModalContext', file: 'src/components/ModalContext.res' },
  { id: '033', name: 'VisualPipeline', file: 'src/components/VisualPipeline.res' },
  { id: '034', name: 'HotspotManager', file: 'src/components/HotspotManager.res' },
  { id: '035', name: 'NotificationContext', file: 'src/components/NotificationContext.res' },
  { id: '036', name: 'ErrorFallbackUI', file: 'src/components/ErrorFallbackUI.res' },
  { id: '037', name: 'HotspotActionMenu', file: 'src/components/HotspotActionMenu.res' },
  { id: '038', name: 'LabelMenu', file: 'src/components/LabelMenu.res' },
  { id: '039', name: 'SceneList', file: 'src/components/SceneList.res' },
  { id: '040', name: 'ViewerFollow', file: 'src/components/ViewerFollow.res' },
  { id: '041', name: 'ViewerManager', file: 'src/components/ViewerManager.res' },
  { id: '042', name: 'ViewerSnapshot', file: 'src/components/ViewerSnapshot.res' },
  { id: '043', name: 'ViewerTypes', file: 'src/components/ViewerTypes.res' },
  { id: '044', name: 'ViewerUI', file: 'src/components/ViewerUI.res' },
  { id: '045', name: 'RemaxErrorBoundary', file: 'src/components/RemaxErrorBoundary.res' },
];

tasks.forEach(t => {
  const filename = `${t.id}_add_tests_${t.name.toLowerCase()}.md`;
  const content = `# Task ${t.id}: Add Unit Tests for ${t.name}

## 🚨 Context
This task was auto-generated because modifications were detected in 

${t.file}

 without corresponding unit tests.

## 🎯 Objective
Create a unit test file to verify the logic in 

${t.file}

## 🛠Implementation Specs
- Create 

tests/unit/${t.name}_v.test.res

 using the 

Vitest

 framework.
- Ensure all tests pass with 

npm test

.
`;
  
  fs.writeFileSync(path.join('tasks/postponed/tests', filename), content);
  console.log(`Created ${filename}`);
});
