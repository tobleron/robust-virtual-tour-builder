import { defineConfig } from '@rsbuild/core';
import { pluginReact } from '@rsbuild/plugin-react';

const buildCommand = process.argv.includes('build') ? 'build' : 'dev';
const isProductionBuild = buildCommand === 'build';
const appMode = isProductionBuild ? 'production' : 'development';

export default defineConfig({
  plugins: [pluginReact()],
  source: {
    entry: {
      index: './src/portal-index.js',
    },
    define: {
      __APP_MODE__: JSON.stringify(appMode),
      __APP_DEV__: JSON.stringify(!isProductionBuild),
      __APP_PROD__: JSON.stringify(isProductionBuild),
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
