export async function exportTourLazy(
  scenes,
  tourName,
  logo,
  projectData,
  signal,
  onProgress,
  opId,
  publishProfiles,
) {
  const mod = await import("./Exporter.bs.js");
  return mod.exportTour(
    scenes,
    tourName,
    logo,
    projectData,
    signal,
    onProgress,
    opId,
    publishProfiles,
  );
}

export async function startTeaserLazy(
  format,
  styleId,
  getState,
  dispatch,
  signal,
  onCancel,
) {
  const mod = await import("./Teaser.bs.js");
  return mod.startHeadlessTeaserWithStyle(
    format,
    styleId,
    getState,
    dispatch,
    signal,
    onCancel,
  );
}

export async function generateExifReportLazy(reportData) {
  const mod = await import("./ExifReportGenerator.bs.js");
  return mod.generateExifReport(reportData);
}

export async function downloadExifReportLazy(content) {
  const mod = await import("./ExifReportGenerator.bs.js");
  return mod.downloadExifReport(content);
}

export async function extractExifFromFileLazy(file) {
  const mod = await import("./ExifParserFacade.bs.js");
  return mod.extractExifFromFile(file);
}
