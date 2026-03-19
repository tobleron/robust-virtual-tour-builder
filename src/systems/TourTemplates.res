open Types

/* --- Submodules (compatibility) --- */
module Assets = TourAssets
module Styles = TourStyles
module Scripts = TourScripts

/* --- Main Logic --- */

let escapeHtml = (raw: string): string => TourTemplateHtml.escapeHtml(raw)

let generateTourHTML = (
  scenes: array<scene>,
  tourName,
  logoFilename: option<string>,
  exportType,
  baseSize,
  logoSize,
  _version,
  ~marketingBody: string="",
  ~marketingShowRent: bool=false,
  ~marketingShowSale: bool=false,
  ~marketingPhone1: string="",
  ~marketingPhone2: string="",
  ~tripodDeadZoneEnabled: bool=true,
) =>
  TourTemplateHtml.generateTourHTML(
    scenes,
    tourName,
    logoFilename,
    exportType,
    baseSize,
    logoSize,
    _version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
    ~tripodDeadZoneEnabled,
  )

// --- COMPATIBILITY ALIASES ---
module TourTemplateAssets = Assets
module TourTemplateStyles = Styles
module TourTemplateScripts = Scripts

let generateEmbedCodes = Assets.generateEmbedCodes
let generateExportIndex = Assets.generateExportIndex
