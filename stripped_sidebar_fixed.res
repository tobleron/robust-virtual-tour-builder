

external asDynamic: 'a => {..} = 

module SidebarTypes = {
  type procState = {
    active: bool,
    progress: float,
    message: string,
    phase: string,
    error: bool,
  }

  type file = ReBindings.File.t

  type processingPayload = {
    : bool,
    : float,
    : string,
    : string,
    : bool,
  }
}

module SidebarLogic = {
  open ReBindings

  let updateProgress = (pct, msg, active, phase) => {
    EventBus.dispatch(
      UpdateProcessing({
        : active,
        : pct,
        : msg,
        : phase,
        : false,
      }),
    )
  }

  let handleUpload = async filesOpt => {
    switch filesOpt {
    | Some(files) if FileList.length(files) > 0 =>
      let fileArray = JsHelpers.from(files)

      try {
        let result: UploadTypes.processResult = await UploadProcessor.processUploads(
          fileArray,
          Some(
            (pct, msg, isProc, phase) => {
              updateProgress(pct, msg, isProc, phase)
            },
          ),
        )

        let qualityResults = result.qualityResults
        let report = result.report

        UploadReport.show(report, qualityResults)
      } catch {
      | JsExn(obj) =>
        let msg = switch JsExn.message(obj) {
        | Some(m) => m
        | None => 
        }
        EventBus.dispatch(ShowNotification( ++ msg, #Error))
        updateProgress(0.0,  ++ msg, false, )
      | _ => ()
      }
    | _ => ()
    }
  }

  let handleLoadProject = async (filesOpt, dispatch, _sceneCount, target) => {
    switch filesOpt {
    | Some(files) if FileList.length(files) > 0 =>
      SessionStore.clearState()
      updateProgress(0.0, , true, )
      try {
        switch FileList.item(files, 0) {
        | Some(file) =>
          Logger.startOperation(
            ~module_=,
            ~operation=,
            ~data={
              : File.name(file),
              : File.size(file),
            },
            (),
          )
          let projectDataResult = await ProjectManager.loadProject(file, ~onProgress=(
            pct,
            _t,
            msg,
          ) => {
            updateProgress(pct->Int.toFloat, msg, true, )
          })

          switch projectDataResult {
          | Ok((sessionId, projectData)) => {
              dispatch(Actions.SetSessionId(sessionId))
              dispatch(Actions.LoadProject(projectData))
              UploadReport.showFromProjectData(projectData)

              Logger.endOperation(
                ~module_=,
                ~operation=,
                ~data={: true},
                (),
              )
              updateProgress(100.0, , false, )
            }
          | Error(msg) => {
              EventBus.dispatch(ShowNotification( ++ msg, #Error))
              updateProgress(0.0,  ++ msg, false, )
              Logger.endOperation(
                ~module_=,
                ~operation=,
                ~data={: false, : msg},
                (),
              )
            }
          }
        | None => ()
        }
      } catch {
      | _ => updateProgress(0.0, , false, )
      }
      asDynamic(target)[] = 
    | _ => ()
    }
  }

  

  let handleExport = async scenes => {
    updateProgress(0.0, , true, )
    try {
      let exportResult = await Exporter.exportTour(
        scenes,
        Some((pct, _, msg) => updateProgress(pct, msg, true, )),
      )
      switch exportResult {
      | Ok() => {
          EventBus.dispatch(ShowNotification(, #Success))
          updateProgress(100.0, , false, )
        }
      | Error(msg) => {
          EventBus.dispatch(ShowNotification( ++ msg, #Error))
          updateProgress(0.0, , false, )
        }
      }
    } catch {
    | _ => updateProgress(0.0, , false, )
    }
  }
}

module SidebarBranding = {
  @react.component
  let make = React.memo(() => {
    React.useEffect0(() => {
      Logger.initialized(~module_=)
      None
    })

    <div className=>
      <div className=>
        <h1 className=>
          {React.string()}
        </h1>
        <LucideIcons.Home className= size=45 />
      </div>
      <div className=>
        {React.string()}
      </div>
      <div
        className=
      >
        <span className=>
          {React.string( ++ Version.version)}
        </span>
        <span className=> {React.string()} </span>
        <span className=> {React.string(Version.buildInfo)} </span>
      </div>
    </div>
  })
}

module SidebarActions = {
  @react.component
  let make = React.memo((
    ~onNew,
    ~onSave,
    ~onLoad,
    ~onAbout,
    ~onExport,
    ~onTeaser,
    ~exportReady,
    ~teaserReady,
  ) => {
    React.useEffect0(() => {
      Logger.initialized(~module_=)
      None
    })

    <div className=>
      <div className=>
        {[
          (, , onNew),
          (, , onSave),
          (, , onLoad),
          (, , onAbout),
        ]
        ->Belt.Array.mapWithIndex((i, (icon, label, onClick)) =>
          <button
            key={Int.toString(i)}
            className=
            onClick={_ => onClick()}
            ariaLabel={label}
          >
            {switch icon {
            |  => <LucideIcons.FilePlus size=20 strokeWidth=1.0 />
            |  => <LucideIcons.Save size=20 strokeWidth=1.0 />
            |  => <LucideIcons.FolderOpen size=20 strokeWidth=1.0 />
            |  => <LucideIcons.Info size=20 strokeWidth=1.0 />
            | _ => React.null
            }}
            <span> {React.string(label)} </span>
          </button>
        )
        ->React.array}
      </div>

      <div className=>
        <button
          className=
          disabled={!exportReady}
          onClick={_ => onExport()}
          ariaLabel=
        >
          <LucideIcons.Download
            className= size=20 strokeWidth=1.0
          />
          <span> {React.string()} </span>
        </button>

        <button
          className=
          disabled={!teaserReady}
          onClick={_ => onTeaser()}
          ariaLabel=
        >
          <LucideIcons.Film
            className= size=20 strokeWidth=1.0
          />
          <span> {React.string()} </span>
        </button>
      </div>
    </div>
  })
}

module SidebarProjectInfo = {
  @react.component
  let make = React.memo((~localTourName, ~onTourNameChange, ~onUploadClick) => {
    React.useEffect0(() => {
      Logger.initialized(~module_=)
      None
    })

    <div className=>
      <div className=>
        <button
          className=
          onClick={_ => onUploadClick()}
        >
          <div
            className=
          />
          <LucideIcons.Camera className= size=24 strokeWidth=2.0 />
          <span
            className=
          >
            {React.string()}
          </span>
        </button>

        <div className=>
          <label className= htmlFor=>
            {React.string()}
          </label>
          <input
            id=
            type_=
            className=
            placeholder=
            value={localTourName}
            onChange={onTourNameChange}
          />
        </div>
      </div>
    </div>
  })
}

module SidebarProcessing = {
  external makeStyle: {..} => ReactDOM.Style.t = 

  @react.component
  let make = React.memo((~procState: SidebarTypes.processingPayload) => {
    React.useEffect0(() => {
      Logger.initialized(~module_=)
      None
    })

    if procState[] {
      <div
        className=
        role=
        ariaLive=#polite
      >
        <div className=>
          <div className=>
            <div className= />
            <div className=>
              {React.string(procState[] ==  ?  : procState[])}
            </div>
          </div>
          <div className=>
            {React.string(Float.toFixed(procState[], ~digits=0) ++ )}
          </div>
        </div>
        <div className=>
          <div
            className=
            style={makeStyle({: Float.toFixed(procState[], ~digits=0) ++ })}
          />
        </div>
        {
          let parts = String.split(procState[], )
          let leftPart = Belt.Array.get(parts, 0)->Option.getOr(procState[])
          let rightPart = Belt.Array.get(parts, 1)->Option.getOr()

          <div
            className=
          >
            <div className=>
              <span className= />
              <span className=> {React.string(leftPart)} </span>
            </div>
            {if rightPart !=  {
              <span className=>
                {React.string(rightPart)}
              </span>
            } else {
              React.null
            }}
          </div>
        }
      </div>
    } else {
      React.null
    }
  })
}

open ReBindings
open SidebarLogic

@scope((, )) @val external reload: unit => unit = 

@react.component
let make = React.memo(() => {
  let state = AppContext.useAppState()
  let sceneSlice = AppContext.useSceneSlice()
  let dispatch = AppContext.useAppDispatch()

  let fileInputRef = React.useRef(Nullable.null)
  let projectFileInputRef = React.useRef(Nullable.null)

  let (procState, setProcState) = React.useState(_ =>
    {
      : false,
      : 0.0,
      : ,
      : ,
      : false,
    }
  )

  let (localTourName, setLocalTourName) = React.useState(() => sceneSlice.tourName)
  let expectedTourName = React.useRef(sceneSlice.tourName)

  React.useEffect1(() => {
    if sceneSlice.tourName != expectedTourName.current {
      setLocalTourName(_ => sceneSlice.tourName)
      expectedTourName.current = sceneSlice.tourName
    }
    None
  }, [sceneSlice.tourName])

  React.useEffect1(() => {
    let timerId = setTimeout(
      () => {
        if localTourName != sceneSlice.tourName {
          expectedTourName.current = localTourName
          dispatch(Actions.SetTourName(localTourName))
        }
      },
      300,
    )
    Some(() => clearTimeout(timerId))
  }, [localTourName])

  let hideTimerRef = React.useRef(Nullable.null)

  React.useEffect0(() => {
    Logger.initialized(~module_=)

    let unsubscribe = EventBus.subscribe(
      event => {
        switch event {
        | UpdateProcessing(payload) =>
          switch Nullable.toOption(hideTimerRef.current) {
          | Some(timerId) =>
            clearTimeout(timerId)
            hideTimerRef.current = Nullable.null
          | None => ()
          }

          setProcState(_ => payload)

          if payload[] >= 100.0 && payload[] {
            let timerId = setTimeout(
              () => {
                setProcState(
                  prev => {
                    let next = Object.assign(Object.make(), prev)
                    next[] = false
                    next
                  },
                )
                hideTimerRef.current = Nullable.null
              },
              3000,
            )
            hideTimerRef.current = Nullable.fromOption(Some(timerId))
          }
        | _ => ()
        }
      },
    )
    Some(unsubscribe)
  })

  let totalHotspots =
    sceneSlice.scenes->Belt.Array.reduce(0, (acc, s) => acc + Array.length(s.hotspots))
  let teaserReady = totalHotspots >= 3
  let exportReady = totalHotspots > 0

  let handleSave = async (state: Types.state) => {
    SidebarLogic.updateProgress(0.0, , true, )
    try {
      let _ = await ProjectManager.saveProject(state, ~onProgress=(pct, _t, msg) => {
        SidebarLogic.updateProgress(pct->Int.toFloat, msg, true, )
      })
      SidebarLogic.updateProgress(100.0, , false, )
    } catch {
    | _ => SidebarLogic.updateProgress(0.0, , false, )
    }
  }

  <div
    className=
  >
    <div className=>
      <SidebarBranding />

      <SidebarActions
        exportReady
        teaserReady
        onNew={() => {
          if Array.length(sceneSlice.scenes) > 0 {
            EventBus.dispatch(
              ShowModal({
                title: ,
                description: Some(
                  ,
                ),
                icon: Some(),
                content: None,
                onClose: None,
                allowClose: Some(true),
                className: Some(),
                buttons: [
                  {
                    label: ,
                    class_: ,
                    onClick: () => (),
                    autoClose: Some(true),
                  },
                  {
                    label: ,
                    class_: ,
                    onClick: () => {
                      SessionStore.clearState()
                      reload()
                    },
                    autoClose: Some(true),
                  },
                ],
              }),
            )
          } else {
            SessionStore.clearState()
            reload()
          }
        }}
        onSave={() => {
          let _ = handleSave(state)
        }}
        onLoad={() => {
          switch Nullable.toOption(projectFileInputRef.current) {
          | Some(el) => Dom.click(el)
          | None => ()
          }
        }}
        onAbout={() => {
          EventBus.dispatch(
            ShowModal({
              title: ,
              description: None,
              icon: Some(),
              content: Some(
                <div className=>
                  <p className=>
                    {React.string()}
                  </p>
                  <p className=>
                    {React.string()}
                  </p>
                </div>,
              ),
              onClose: None,
              allowClose: Some(true),
              className: Some(),
              buttons: [
                {
                  label: ,
                  class_: ,
                  onClick: () => (),
                  autoClose: Some(true),
                },
              ],
            }),
          )
        }}
        onExport={() => {
          let _ = handleExport(sceneSlice.scenes)
        }}
        onTeaser={() => {
          let _ = Teaser.startAutoTeaser(sceneSlice.tourName, false, , false)
        }}
      />

      <input
        type_=
        ref={ReactDOM.Ref.domRef(fileInputRef)}
        multiple=true
        accept=
        className=
        onChange={e => {
          let target = JsxEvent.Form.target(e)->Dom.unsafeToElement
          let _ = handleUpload(Dom.getFiles(target))
        }}
      />
      <input
        type_=
        ref={ReactDOM.Ref.domRef(projectFileInputRef)}
        accept=
        className=
        onChange={e => {
          let target = JsxEvent.Form.target(e)->Dom.unsafeToElement
          let _ = handleLoadProject(
            Dom.getFiles(target),
            dispatch,
            Array.length(sceneSlice.scenes),
            target,
          )
        }}
      />
    </div>

    <SidebarProjectInfo
      localTourName
      onTourNameChange={e => {
        let val = JsxEvent.Form.target(e)[]
        setLocalTourName(_ => val)
      }}
      onUploadClick={() => {
        switch Nullable.toOption(fileInputRef.current) {
        | Some(el) => Dom.click(el)
        | None => ()
        }
      }}
    />

    <SidebarProcessing procState />

    <div
      className=
    >
      <div className=>
        <SceneList />
      </div>
    </div>
  </div>
})
