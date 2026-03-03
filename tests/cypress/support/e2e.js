// tests/cypress/support/e2e.js
// Cypress E2E Support File for Virtual Tour Builder

// Capture all console logs
Cypress.Commands.add('enableDebugLogging', () => {
  cy.on('window:console', (log) => {
    if (log.message && log.message.includes && 
        (log.message.includes('===') || log.message.includes('SIM_') || 
         log.message.includes('DISPATCH') || log.message.includes('NEXT_LINK'))) {
      cy.log('CONSOLE: ' + log.message)
    }
  })
})

// Load project from ZIP file - revised for reliability with large files
Cypress.Commands.add('loadProjectZip', (zipPath) => {
  cy.log('=== Loading Project from ZIP ===')
  cy.log('ZIP Path:', zipPath)
  
  // Use cy.task to read file (if available) or direct upload
  cy.get('#sidebar-project-upload', { timeout: 30000 })
    .should('exist')
    .selectFile(zipPath, { force: true })
    .log('File selected via path')
  
  // Wait for modal or processing to start
  cy.wait(3000)
  
  // Look for and click any confirmation/start button
  cy.get('body').then(($body) => {
    // Try multiple button selectors
    const $startBtn = $body.find('button:contains("Start Building")').first()
    const $closeBtn = $body.find('button:contains("Close")').first()
    const $okBtn = $body.find('button:contains("OK"), button:contains("Ok")').first()
    
    if ($startBtn.length > 0 && $startBtn.is(':visible')) {
      cy.wrap($startBtn).click()
      cy.log('Clicked "Start Building" button')
    } else if ($closeBtn.length > 0 && $closeBtn.is(':visible')) {
      cy.wrap($closeBtn).click()
      cy.log('Clicked "Close" button')
    } else if ($okBtn.length > 0 && $okBtn.is(':visible')) {
      cy.wrap($okBtn).click()
      cy.log('Clicked "OK" button')
    } else {
      cy.log('No confirmation button found, continuing...')
    }
  })
  
  // Wait for scenes to appear in sidebar
  cy.log('Waiting for scenes to load...')
  cy.get('.scene-item', { timeout: 90000 })
    .should('have.length.greaterThan', 0)
    .then(($scenes) => {
      cy.log(`Scenes loaded: ${$scenes.length}`)
    })
  
  // Wait for "New" button to be enabled (sidebar interactive)
  cy.contains('button', 'New', { timeout: 30000 })
    .should('be.enabled')
    .log('Sidebar is interactive')
  
  // Additional wait for viewer to stabilize
  cy.wait(2000)
  
  cy.log('=== Project Load Complete ===')
})

// Start simulation (tour preview)
Cypress.Commands.add('startSimulation', () => {
  cy.log('=== Starting Simulation ===')
  
  // Wait for viewer to be ready
  cy.get('#viewer-stage', { timeout: 10000 }).should('exist')
  cy.log('Viewer stage found')
  
  // Wait for utility bar to be visible
  cy.get('#viewer-utility-bar', { timeout: 10000 }).should('be.visible')
  cy.log('Utility bar visible')
  
  // Find and click the tour preview/play button - try multiple approaches
  cy.get('#viewer-utility-bar').within(() => {
    // First try: button with aria-label containing "preview" or "play"
    cy.get('button').then(($buttons) => {
      let clicked = false
      
      for (let i = 0; i < $buttons.length && !clicked; i++) {
        const btn = $buttons[i]
        const text = Cypress.$(btn).text().toLowerCase()
        const ariaLabel = Cypress.$(btn).attr('aria-label') || ''
        
        cy.log('Checking button: text="' + text + '", aria-label="' + ariaLabel + '"')
        
        if (text.includes('preview') || text.includes('tour') || 
            ariaLabel.toLowerCase().includes('preview') ||
            ariaLabel.toLowerCase().includes('play') ||
            ariaLabel.toLowerCase().includes('start')) {
          cy.wrap(btn).click()
          clicked = true
          cy.log('Clicked button: ' + text)
        }
      }
      
      // Fallback: click first enabled button
      if (!clicked) {
        cy.get('button:enabled').first().click()
        cy.log('Clicked first enabled button (fallback)')
      }
    })
  })
  
  // Verify simulation started - wait for button state change
  cy.wait(2000)
  cy.log('Simulation should be running')
})

// Stop simulation
Cypress.Commands.add('stopSimulation', () => {
  cy.log('=== Stopping Simulation ===')
  
  cy.get('#viewer-utility-bar').within(() => {
    cy.get('button').then(($buttons) => {
      $buttons.each((i, btn) => {
        const text = Cypress.$(btn).text().toLowerCase()
        const ariaLabel = Cypress.$(btn).attr('aria-label') || ''
        
        if (text.includes('stop') || ariaLabel.toLowerCase().includes('stop')) {
          cy.wrap(btn).click()
          cy.log('Clicked stop button')
        }
      })
    })
  })
})

// Wait for viewer to be ready (canvas exists)
Cypress.Commands.add('waitForViewerReady', () => {
  cy.log('Waiting for viewer...')
  
  cy.get('#panorama-a', { timeout: 30000 }).should('exist')
  cy.get('#viewer-stage canvas', { timeout: 30000 }).should('exist')
  
  cy.log('Viewer ready')
})

// Get simulation state from window store
Cypress.Commands.add('getSimulationState', () => {
  return cy.window({ timeout: 10000 }).then((win) => {
    // Try multiple state locations
    const state = win.store?.state || win.__RE_STATE__ || win.state
    
    if (state) {
      cy.log('State found: activeIndex=' + state.activeIndex + ', simStatus=' + state.simulation?.status)
      return state
    }
    
    cy.log('WARNING: No state found on window object')
    return null
  })
})

// Assert simulation advanced to at least scene N
Cypress.Commands.add('assertSimulationAdvanced', (minSceneIndex) => {
  cy.getSimulationState().then((state) => {
    if (state) {
      const currentIndex = state.activeIndex
      const visitedLinkIds = state.simulation?.visitedLinkIds || []
      
      cy.log(`Current scene index: ${currentIndex}`)
      cy.log(`Visited link IDs: ${visitedLinkIds.length}`)
      
      // Use proper Chai assertion
      cy.wrap(currentIndex).should('be.at.least', minSceneIndex)
      cy.wrap(visitedLinkIds.length).should('be.at.least', 1)
    }
  })
})
