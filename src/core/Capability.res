
type capability =
  | CanNavigate
  | CanEditHotspots
  | CanUpload
  | CanExport
  | CanMutateProject
  | CanStartSimulation
  | CanInteractWithViewer

module Policy = {
  // Helper to check if any operation matches a predicate
  let anyActive = (ops: array<OperationLifecycle.task>, predicate: OperationLifecycle.task => bool) => {
    ops->Belt.Array.some(op => {
      switch op.status {
      | Active(_) | Paused => predicate(op)
      | _ => false
      }
    })
  }

  let isCritical = (type_: OperationLifecycle.operationType) => {
    switch type_ {
    | ProjectLoad | ProjectSave | Export | SceneLoad => true
    | _ => false
    }
  }

  let evaluate = (capability: capability, operations: array<OperationLifecycle.task>) => {
    // 1. Check for Critical Locks (System Blocking)
    // If any critical operation is active, virtually everything is blocked
    let systemLocked = anyActive(operations, op => isCritical(op.type_))

    if systemLocked {
      false
    } else {
      // 2. Check Capability-Specific Policies
      switch capability {
      | CanNavigate =>
        // Block navigation if:
        // - Another navigation is currently active (prevent double-click race)
        // - Simulation is running
        !anyActive(operations, op => {
          switch op.type_ {
          | Navigation | Simulation => true
          | _ => false
          }
        })

      | CanEditHotspots =>
        // Block editing if:
        // - Navigation is active (can't click hotspots while moving)
        // - Simulation is running
        !anyActive(operations, op => {
          switch op.type_ {
          | Navigation | Simulation => true
          | _ => false
          }
        })

      | CanUpload =>
        // Block upload if:
        // - Another upload is active (simplification)
        !anyActive(operations, op => {
          switch op.type_ {
          | Upload => true
          | _ => false
          }
        })

      | CanExport =>
        // Block export if:
        // - Upload active (data changing)
        // - Thumbnail generation active (assets missing?)
        !anyActive(operations, op => {
          switch op.type_ {
          | Upload | ThumbnailGeneration => true
          | _ => false
          }
        })

      | CanMutateProject =>
        // Block structural changes (delete/reorder scenes) if:
        // - Upload active
        // - Simulation running
        // - Thumbnail generation active (referencing specific scenes)
        !anyActive(operations, op => {
          switch op.type_ {
          | Upload | Simulation | ThumbnailGeneration => true
          | _ => false
          }
        })

      | CanStartSimulation =>
        // Block starting sim if:
        // - Already running
        // - Navigation active
        // - Upload active (performance)
        !anyActive(operations, op => {
          switch op.type_ {
          | Simulation | Navigation | Upload => true
          | _ => false
          }
        })

      | CanInteractWithViewer =>
        // General viewer interaction (pan/zoom)
        // Block if navigation is active (prevent fighting camera)
        !anyActive(operations, op => {
          switch op.type_ {
          | Navigation => true
          | _ => false
          }
        })
      }
    }
  }
}

let useCapability = (capability: capability) => {
  let ops = OperationLifecycle.useOperations()
  Policy.evaluate(capability, ops)
}

let useIsSystemLocked = () => {
  let ops = OperationLifecycle.useOperations()
  Policy.anyActive(ops, op => Policy.isCritical(op.type_))
}
