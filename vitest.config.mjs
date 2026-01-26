import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        include: ['tests/**/*.test.bs.js', 'tests/unit/AppContextTest.bs.js', 'tests/unit/UiReducerTest.bs.js'],
        environment: 'jsdom',
        globals: true,
        setupFiles: [
            'tests/unit/LabelMenu_v.test.setup.jsx',
            'tests/unit/UploadProcessor_v.test.setup.js',
            'tests/unit/HotspotLine_v.test.setup.js',
            'tests/unit/Components_v.test.setup.jsx'
        ],
        server: {
            deps: {
                inline: ['sonner']
            }
        }
    },
});
