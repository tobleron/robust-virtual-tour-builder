// @efficiency-role: state-hook
open Types
open Actions
open ReBindings

let useSystemLockLogging = (~isSystemLocked: bool) => {
  React.useEffect1(() => {
    Logger.debug(
      ~module_="App",
      ~message="SYSTEM_LOCKED_STATUS: " ++ (isSystemLocked ? "LOCKED" : "UNLOCKED"),
      (),
    )
    None
  }, [isSystemLocked])
}

let useBodyModeClasses = (~isExporting: bool, ~isProjectLoading: bool) => {
  React.useEffect2(() => {
    let bodyClasses = Dom.classList(Dom.documentBody)
    if isExporting {
      bodyClasses->Dom.ClassList.add("export-mode")
    } else {
      bodyClasses->Dom.ClassList.remove("export-mode")
    }
    if isProjectLoading {
      bodyClasses->Dom.ClassList.add("project-load-mode")
    } else {
      bodyClasses->Dom.ClassList.remove("project-load-mode")
    }
    None
  }, (isExporting, isProjectLoading))
}

let useInitComplete = (~dispatch: action => unit) => {
  React.useEffect0(() => {
    Logger.debug(~module_="App", ~message="InnerApp Mounted - DISPATCHING_INIT_COMPLETE", ())
    dispatch(DispatchAppFsmEvent(InitializeComplete))
    None
  })
}

let useBootProject = (
  ~bootProjectData: option<JSON.t>,
  ~bootProjectSessionId: option<string>,
  ~bootProjectLabel: option<string>,
  ~loadSavedProject: (~sessionId: string, ~projectData: JSON.t, ~label: string) => Promise.t<unit>,
) => {
  React.useEffect3(() => {
    switch (bootProjectData, bootProjectSessionId) {
    | (Some(projectData), Some(sessionId)) =>
      let _ = %raw(
        "((w) => { w.__VTB_BOOT_PROJECT_DATA__ = undefined; w.__VTB_BOOT_PROJECT_SESSION_ID__ = undefined; w.__VTB_BOOT_PROJECT_LABEL__ = undefined; })(window)"
      )
      loadSavedProject(
        ~sessionId,
        ~projectData,
        ~label=bootProjectLabel->Option.getOr("saved tour"),
      )
      ->Promise.catch(_ => Promise.resolve())
      ->ignore
    | _ => ()
    }
    None
  }, (bootProjectData, bootProjectSessionId, bootProjectLabel))
}

let useExposeState = (~state: state) => {
  React.useEffect1(() => {
    let _ = %raw("((s) => { window.__RE_STATE__ = s })(state)")
    None
  }, [state])
}

let useExposeLifecycleBridges = () => {
  React.useEffect0(() => {
    let _ = %raw("(isBusyFn, evaluateFn) => {
      window.OperationLifecycle = {
        isBusy: (opts) => {
          const t = opts ? opts.type : undefined;
          const s = opts ? opts.scope : undefined;
          return isBusyFn(t, s, undefined);
        }
      };
      window.Capability = {
        evaluate: (opts) => {
           return evaluateFn(opts.capability, opts.appMode, opts.operations);
        }
      };
    }")(OperationLifecycle.isBusy, Capability.Policy.evaluate)
    None
  })
}
