#!/bin/bash
# Script to monitor simulation diagnostic logs in real-time

echo "=== Simulation Diagnostic Monitor ==="
echo "Watching for simulation events..."
echo "Press Ctrl+C to stop"
echo ""

# This will be populated by browser console logs
# For now, just show instructions
cat << 'EOF'
INSTRUCTIONS:
1. Open your browser's Developer Console (F12 or Cmd+Option+I)
2. Filter logs by typing: SIM_
3. Start the tour preview mode
4. Watch for these key messages:

   - SIM_TICK_WAIT: Simulation is waiting before advancing
   - SIM_WAIT_FOR_VIEWER: Waiting for viewer to be ready
   - SIM_READY_TO_ADVANCE: FSM is idle, about to check next move
   - SIM_ADVANCING: Actually navigating to next scene
   - SIM_TICK_ABORTED_OR_BUSY: Blocked (check fsmState in the log)
   - SIM_NO_MOVE: No valid next move found
   - SIM_COMPLETE: Tour finished

If you see SIM_TICK_ABORTED_OR_BUSY repeatedly, note the fsmState value.
If you see SIM_READY_TO_ADVANCE but no SIM_ADVANCING, the issue is in getNextMove().

EOF
