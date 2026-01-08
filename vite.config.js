import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    port: 9999,
    strictPort: true,
  },
  build: {
    outDir: 'dist',
    minify: 'terser',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['./src/libs/pannellum.js', './src/libs/jszip.min.js', './src/libs/FileSaver.min.js'],
        },
      },
    },
  },
  // Ensure that absolute paths in index.html are handled correctly if needed
  base: './',
});
