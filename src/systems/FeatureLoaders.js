export async function exportTourLazy(
  scenes,
  tourName,
  logo,
  projectData,
  signal,
  onProgress,
  opId,
) {
  const mod = await import("./Exporter.bs.js");
  return mod.exportTour(scenes, tourName, logo, projectData, signal, onProgress, opId);
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
