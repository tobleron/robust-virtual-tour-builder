const { defineConfig } = require('cypress')

module.exports = defineConfig({
  projectId: 'vtb-simulation-test',
  e2e: {
    baseUrl: 'http://localhost:3000',
    supportFile: 'tests/cypress/support/e2e.js',
    specPattern: 'tests/cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    video: true,
    screenshotOnRunFailure: true,
    viewportWidth: 1280,
    viewportHeight: 720,
    defaultCommandTimeout: 30000,
    requestTimeout: 30000,
    responseTimeout: 60000,
    pageLoadTimeout: 60000,
    chromeWebSecurity: false,
  },
  videosFolder: 'tests/cypress/videos',
  screenshotsFolder: 'tests/cypress/screenshots',
})
