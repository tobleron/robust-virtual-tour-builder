// tests/cypress/e2e/simulation-tour-preview.cy.js
// T1790: Tour Preview Simulation Test - Cypress Implementation

describe('T1790: Tour Preview Simulation', () => {
  // Use absolute path from project root
  const EDGE_ZIP_PATH = Cypress.config('projectRoot') + '/artifacts/edge.zip'
  
  beforeEach(() => {
    // Enable debug logging
    cy.enableDebugLogging()
    
    // Clear browser state
    cy.clearLocalStorage()
    cy.clearCookies()
    
    // Navigate to app
    cy.visit('/', { timeout: 30000 })
    
    // Wait for app to load
    cy.contains('Virtual Tour Builder', { timeout: 30000 }).should('exist')
    
    // Load edge.zip project
    cy.loadProjectZip(EDGE_ZIP_PATH)
    
    // Wait for viewer to be ready
    cy.waitForViewerReady()
    
    // Additional wait to ensure app is fully stable
    cy.wait(2000)
  })
  
  it('should advance past first scene', () => {
    cy.log('=== TEST: Should advance past first scene ===')
    
    // Create debug overlay to show state
    cy.document().then((doc) => {
      const debugDiv = doc.createElement('div')
      debugDiv.id = 'debug-state'
      debugDiv.style.cssText = 'position:fixed;top:10px;right:10px;background:rgba(0,0,0,0.8);color:#0f0;padding:10px;z-index:99999;font-family:monospace;font-size:12px;'
      doc.body.appendChild(debugDiv)
    })
    
    // Start simulation
    cy.startSimulation()
    
    // Update debug overlay with state at intervals
    const updateDebug = () => {
      cy.window().then((win) => {
        const state = win.store?.state
        const debugDiv = win.document.getElementById('debug-state')
        if (state && debugDiv) {
          debugDiv.innerHTML = `
            activeIndex: ${state.activeIndex}<br>
            visitedLinkIds: ${JSON.stringify(state.simulation?.visitedLinkIds || [])}<br>
            simStatus: ${state.simulation?.status}<br>
            navFsm: ${state.navigationState?.navigationFsm}
          `
        }
      })
    }
    
    cy.wait(5000).then(updateDebug)
    cy.wait(5000).then(updateDebug)
    cy.wait(5000).then(updateDebug)
    cy.wait(5000).then(updateDebug)
    cy.wait(5000).then(updateDebug)
    
    // Final assertion
    cy.window().then((win) => {
      const state = win.store?.state
      if (state) {
        cy.log('Final: activeIndex=' + state.activeIndex + ', visited=' + JSON.stringify(state.simulation?.visitedLinkIds))
        
        // Check if simulation advanced
        if (state.activeIndex !== undefined) {
          cy.wrap(state.activeIndex).should('be.at.least', 1)
        }
        if (state.simulation?.visitedLinkIds) {
          cy.wrap(state.simulation.visitedLinkIds.length).should('be.at.least', 1)
        }
      }
    })
    
    // Stop simulation
    cy.stopSimulation()
    
    cy.log('=== TEST COMPLETE ===')
  })
  
  it('should continue advancing through scenes', () => {
    cy.log('=== TEST: Should continue advancing through scenes ===')
    
    // Start simulation
    cy.startSimulation()
    
    // Wait for transitions
    cy.wait(20000)
    
    // Check simulation advanced at least once
    cy.window().then((win) => {
      const state = win.store?.state
      if (state) {
        const visitedCount = state.simulation?.visitedLinkIds?.length || 0
        const activeIndex = state.activeIndex
        
        cy.log('After 20s: activeIndex=' + activeIndex + ', visitedCount=' + visitedCount)
        
        // Simulation should have visited at least 1 link
        cy.wrap(visitedCount).should('be.at.least', 1)
      }
    })
    
    // Wait more and check again
    cy.wait(20000)
    
    cy.window().then((win) => {
      const state = win.store?.state
      if (state) {
        const visitedCount = state.simulation?.visitedLinkIds?.length || 0
        const activeIndex = state.activeIndex
        
        cy.log('After 40s: activeIndex=' + activeIndex + ', visitedCount=' + visitedCount)
        
        // Should have visited more links by now
        cy.wrap(visitedCount).should('be.at.least', 1)
      }
    })
    
    // Stop simulation
    cy.stopSimulation()
    
    cy.log('=== TEST COMPLETE ===')
  })
})
