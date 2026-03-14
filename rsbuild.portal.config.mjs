import { defineConfig } from '@rsbuild/core';
import { pluginReact } from '@rsbuild/plugin-react';

export default defineConfig({
  plugins: [pluginReact()],
  source: {
    entry: {
      index: './src/portal-index.js',
    },
  },
  resolve: {
    alias: {
      '@': './src',
    },
  },
  html: {
    template: './portal.index.html',
    templateParameters: {
      title: 'Robust Virtual Tour Builder Portal',
      description: 'Private customer portal for published Robust Virtual Tour Builder tours.',
      publicUrl: process.env.PUBLIC_URL || '',
      author: 'Robust Virtual Tour Builder',
      siteName: 'Robust Virtual Tour Builder Portal',
    },
  },
  output: {
    distPath: {
      root: 'dist-portal',
      js: 'static/js',
      css: 'static/css',
      svg: 'static/svg',
      font: 'static/font',
      image: 'static/images',
      media: 'static/media',
    },
    filenameHash: true,
    cleanDistPath: true,
    manifest: 'asset-manifest.json',
    injectStyles: true,
    sourceMap: {
      js: 'source-map',
      css: true,
    },
  },
  performance: {
    chunkSplit: {
      strategy: 'split-by-module',
    },
    removeConsole: true,
  },
});
