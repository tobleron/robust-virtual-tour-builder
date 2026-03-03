// tests/cypress/e2e/simulation-tour-preview.cy.js
// T1790: Tour Preview Simulation Test - Cypress Implementation
// Verifies: Load project -> Start Building dialog -> Tour Preview -> 4+ scene transitions

describe('T1790: Tour Preview Simulation', () => {
  // Use absolute path from project root
  const EDGE_ZIP_PATH = Cypress.config('projectRoot') + '/artifacts/edge.zip'
  const readState = (win) => win.__RE_STATE__ || win.store?.state || null

  beforeEach(() => {
    // Clear browser state
    cy.clearLocalStorage()
    cy.clearCookies()

    // Navigate to app
    cy.visit('/', { timeout: 30000 })

    // Wait for app to load
    cy.contains('Virtual Tour Builder', { timeout: 30000 }).should('exist')

    // Load edge.zip project
    cy.loadProjectZip(EDGE_ZIP_PATH)

    // Enter builder if upload summary modal is present.
    cy.clickStartBuildingIfPresent()

    // Wait for viewer to be ready
    cy.waitForViewerReady()
  })

  it('should complete full flow: Start Building -> Tour Preview -> 4+ scene transitions', () => {
    cy.log('=== TEST: Full Tour Preview Flow (4+ Transitions) ===')

    // Safety: if modal still exists, close it.
    cy.clickStartBuildingIfPresent()

    // Step 1: Start tour preview simulation
    cy.startSimulation()

    cy.log('Simulation started, waiting for scene transitions...')

    // Step 2: Wait until simulation clearly continues.
    const startedAt = Date.now()
    const waitForProgress = () => {
      cy.window().then((win) => {
        const state = readState(win)
        const visitedCount = state?.simulation?.visitedLinkIds?.length || 0
        const activeIndex = state?.activeIndex ?? -1
        cy.log(`Progress: scene=${activeIndex}, visitedLinks=${visitedCount}`)

        if (visitedCount >= 4 && activeIndex >= 1) {
          return
        }

        if (Date.now() - startedAt > 120000) {
          throw new Error(
            `Simulation did not reach expected progress in time. activeIndex=${activeIndex}, visitedLinks=${visitedCount}`,
          )
        }

        cy.wait(2000).then(waitForProgress)
      })
    }
    waitForProgress()

    // Step 4: Final assertion - verify at least 4 scene transitions occurred
    cy.window().then((win) => {
      const state = readState(win)
      if (state) {
        const visitedCount = state.simulation?.visitedLinkIds?.length || 0
        const activeIndex = state.activeIndex

        cy.log('=== FINAL STATE ===')
        cy.log(`Active Scene Index: ${activeIndex}`)
        cy.log(`Total Transitions: ${visitedCount}`)
        cy.log(`Visited Link IDs: ${JSON.stringify(state.simulation?.visitedLinkIds)}`)

        // Assert at least 4 transitions (visitedLinkIds tracks completed transitions)
        cy.wrap(visitedCount, 'Number of scene transitions').should('be.at.least', 4, {
          timeout: 5000,
          message: 'Expected at least 4 scene transitions in tour preview'
        })

        // Also verify we've moved through multiple scenes
        cy.wrap(activeIndex, 'Active scene index').should('be.at.least', 1, {
          message: 'Expected to have advanced beyond first scene'
        })
      }
    })

    // Step 5: Stop simulation
    cy.log('Stopping simulation')
    cy.stopSimulation()

    cy.log('=== TEST COMPLETE: 4+ transitions verified ===')
  })

  it('should advance past first scene (legacy test)', () => {
    cy.log('=== TEST: Should advance past first scene ===')

    cy.clickStartBuildingIfPresent()

    // Start simulation
    cy.startSimulation()

    // Wait for simulation to run
    cy.wait(35000)

    // Check simulation state
    cy.window().then((win) => {
      const state = readState(win)
      if (state) {
        cy.log('Final: activeIndex=' + state.activeIndex + ', visited=' + JSON.stringify(state.simulation?.visitedLinkIds))

        // Should have advanced at least to scene 2 (index 1)
        cy.wrap(state.activeIndex).should('be.at.least', 1)
        cy.wrap(state.simulation?.visitedLinkIds?.length || 0).should('be.at.least', 1)
      }
    })

    // Stop simulation
    cy.stopSimulation()

    cy.log('=== TEST COMPLETE ===')
  })
})
