// tests/cypress/support/e2e.js
// Cypress E2E Support File for Virtual Tour Builder

const getAppState = (win) => win.__RE_STATE__ || win.store?.state || null

// Load project from ZIP file
Cypress.Commands.add('loadProjectZip', (zipPath) => {
  cy.log('=== Loading Project from ZIP ===')

  // Wait for backend to be ready
  cy.wait(2000)

  // Use the sidebar upload input
  cy.get('#sidebar-project-upload', { timeout: 30000 })
    .should('exist')
    .selectFile(zipPath, { force: true })

  // Trigger change event manually (Cypress may not auto-trigger)
  cy.get('#sidebar-project-upload').then(($el) => {
    $el[0].dispatchEvent(new Event('change', { bubbles: true }))
  })

  cy.log('File uploaded, waiting for processing...')

  // Wait for either:
  // 1. Upload summary modal with "Start Building" button (new flow)
  // 2. Scene items in sidebar (legacy flow)
  // Use longer timeout for project processing
  cy.get('button:contains("Start Building"), .scene-item', { timeout: 120000 })
    .should('exist')

  cy.log('Project loaded, sidebar is interactive')
})

Cypress.Commands.add('clickStartBuildingIfPresent', () => {
  cy.get('body', { timeout: 15000 }).then(($body) => {
    const startBuildingExists = $body.find('button:contains("Start Building")').length > 0
    const closeExists = $body.find('button:contains("Close")').length > 0

    if (startBuildingExists) {
      cy.contains('button', 'Start Building')
        .should('be.visible')
        .should('be.enabled')
        .click()
    } else if (closeExists) {
      cy.contains('button', 'Close')
        .should('be.visible')
        .should('be.enabled')
        .click()
    }
  })
})

// Start simulation (tour preview)
Cypress.Commands.add('startSimulation', () => {
  cy.log('=== Starting Simulation ===')

  // Wait for viewer
  cy.get('#viewer-stage', { timeout: 10000 }).should('exist')

  // Click Tour Preview button.
  cy.get('#viewer-utility-bar').within(() => {
    cy.get(
      'button[aria-label*="Tour Preview"], button[title*="Tour Preview"], button:has([class*="lucide-play"])',
    )
      .first()
      .should('be.visible')
      .should('be.enabled')
      .click({ force: true })
  })

  cy.window({ timeout: 30000 }).should((win) => {
    const state = getAppState(win)
    expect(state?.simulation?.status).to.eq('Running')
  })
  cy.log('Simulation started')
})

// Stop simulation
Cypress.Commands.add('stopSimulation', () => {
  cy.log('=== Stopping Simulation ===')
  
  cy.get('#viewer-utility-bar').within(() => {
    cy.get(
      'button[aria-label*="Stop"], button[title*="Stop"], button:has([class*="lucide-square"])',
    )
      .first()
      .should('be.visible')
      .click({ force: true })
  })

  cy.window({ timeout: 30000 }).should((win) => {
    const state = getAppState(win)
    expect(state?.simulation?.status).not.to.eq('Running')
  })

  cy.log('Simulation stopped')
})

// Wait for viewer to be ready
Cypress.Commands.add('waitForViewerReady', () => {
  const timeoutMs = 90000
  const pollIntervalMs = 1000
  const fallbackAfterMs = 15000
  const startedAt = Date.now()
  let didFallbackNavigation = false

  const hasViewerCanvas = () =>
    cy.get('body').then(($body) => $body.find('#viewer-stage canvas').length > 0)

  const triggerFallbackNavigation = () => {
    cy.log('Viewer canvas missing, forcing scene reselection fallback...')
    cy.get('.scene-item', { timeout: 30000 }).then(($items) => {
      const itemCount = $items.length
      if (itemCount >= 2) {
        cy.wrap($items.eq(1)).click({ force: true })
        cy.wait(1200)
        cy.wrap($items.eq(0)).click({ force: true })
      } else if (itemCount === 1) {
        cy.wrap($items.eq(0)).click({ force: true })
      }
    })
  }

  const poll = () => {
    cy.window({ timeout: 30000 }).then((win) => {
      const state = getAppState(win)
      expect(state, 'app state').to.exist
      expect(state.activeIndex, 'active scene index').to.be.gte(0)
    })

    hasViewerCanvas().then((ready) => {
      if (ready) {
        cy.log('Viewer canvas is ready.')
        return
      }

      const elapsed = Date.now() - startedAt
      if (!didFallbackNavigation && elapsed >= fallbackAfterMs) {
        didFallbackNavigation = true
        triggerFallbackNavigation()
      }

      if (elapsed >= timeoutMs) {
        throw new Error('Viewer canvas did not appear within wait window')
      }

      cy.wait(pollIntervalMs).then(poll)
    })
  }

  poll()
})
