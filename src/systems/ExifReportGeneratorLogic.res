/* src/systems/ExifReportGeneratorLogic.res */
// @efficiency-role: orchestrator

include ExifReportGeneratorLogicTypes

module Extraction = ExifReportGeneratorLogicExtraction
module Location = ExifReportGeneratorLogicLocation
module Groups = ExifReportGeneratorLogicGroups

// Alias Utils for backward compatibility if needed, though most use ExifUtils directly now
module Utils = ExifUtils
