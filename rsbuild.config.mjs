import { defineConfig } from '@rsbuild/core';
import { pluginReact } from '@rsbuild/plugin-react';

export default defineConfig({
  plugins: [pluginReact()],
  source: {
    entry: {
      index: './src/index.js',
    },
  },
  html: {
    template: './index.html',
  },
  output: {
    // Output to dist/ directory for production builds
    distPath: {
      root: 'dist',
      js: 'static/js',
      css: 'static/css',
      svg: 'static/svg',
      font: 'static/font',
      image: 'static/images',
      media: 'static/media',
    },
    // Enable content-based hashing for cache busting
    filenameHash: true,
    // Clean dist folder before each build
    cleanDistPath: true,
    // Source maps for production debugging
    sourceMap: {
      js: 'source-map',
      css: true,
    },
  },
  performance: {
    // Chunk splitting for better caching
    chunkSplit: {
      strategy: 'split-by-experience',
    },
    // Remove console logs in production
    removeConsole: true,
  },
  server: {
    proxy: {
      '/api': 'http://localhost:8080',
      '/session': 'http://localhost:8080',
    },
  },
});
