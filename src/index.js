/**
 * Application Entry Point
 * 
 * This file serves as the entry point for Rsbuild. It imports the CSS
 * (which includes Tailwind directives) and then imports the ReScript-compiled
 * Main.bs.js module.
 */

// Import Tailwind CSS (Rsbuild will process this through PostCSS)
import '../css/tailwind.css';
import '../css/style.css';

// Import the ReScript-compiled main module
import './Main.bs.js';
