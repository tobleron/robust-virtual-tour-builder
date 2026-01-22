import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        include: ['tests/**/*.test.bs.js'],
        environment: 'jsdom',
        globals: true,
    },
});
