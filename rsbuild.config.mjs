import { defineConfig } from '@rsbuild/core';
import { pluginReact } from '@rsbuild/plugin-react';

export default defineConfig({
  plugins: [pluginReact()],
  source: {
    entry: {
      index: './src/index.js',
    },
  },
  resolve: {
    alias: {
      '@': './src',
    },
  },
  html: {
    template: './index.html',
    templateParameters: {
      title: process.env.APP_TITLE || 'Remax Virtual Tour Builder',
      description: process.env.APP_DESCRIPTION || 'Professional-grade virtual tour builder for real estate. Create immersive 360° panoramic tours with hotspot navigation, automated path generation, and high-quality exports.',
      publicUrl: process.env.PUBLIC_URL || '',
      author: 'Remax',
      siteName: 'Remax Virtual Tour Builder',
    },
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
    // Generate asset manifest for service worker
    manifest: 'asset-manifest.json',
    // Inject styles into <style> tags in development (avoid HMR loops)
    injectStyles: true,
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
      '/api': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: true,
        secure: false,
      },
      '/session': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: true,
        secure: false,
      },
      '/health': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: true,
        secure: false,
      },
    },
  },
});
