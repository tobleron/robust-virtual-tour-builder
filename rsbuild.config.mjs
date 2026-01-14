import { defineConfig } from '@rsbuild/core';
import { pluginReact } from '@rsbuild/plugin-react';

export default defineConfig({
  plugins: [pluginReact()],
  source: {
    entry: {
      index: './src/Main.bs.js',
    },
  },
  html: {
    template: './index.html',
  },
  server: {
    proxy: {
      '/api': 'http://localhost:8080',
      '/session': 'http://localhost:8080',
    },
  },
});
