/* src/Store.res */

// --- ABSTRACT TYPES ---
type file

// --- TYPES ---

type transition = {
  @as("type") type_: Nullable.t<string>,
  targetHotspotIndex: int,
  fromSceneName: Nullable.t<string>,
}

type viewFrame = {
  yaw: float,
  pitch: float,
  hfov: float,
}

type rec linkDraft = {
  pitch: float,
  yaw: float,
  camPitch: float,
  camYaw: float,
  camHfov: float,
  intermediatePoints: Nullable.t<array<linkDraft>>,
}

type hotspot = {
  mutable linkId: string,
  mutable yaw: float,
  mutable pitch: float,
  mutable target: string,
  mutable targetYaw: Nullable.t<float>,
  mutable targetPitch: Nullable.t<float>,
  mutable targetHfov: Nullable.t<float>,
  mutable startYaw: Nullable.t<float>,
  mutable startPitch: Nullable.t<float>,
  mutable startHfov: Nullable.t<float>,
  mutable isReturnLink: Nullable.t<bool>,
  mutable viewFrame: Nullable.t<viewFrame>,
  mutable returnViewFrame: Nullable.t<viewFrame>,
  mutable waypoints: Nullable.t<array<viewFrame>>,
  mutable displayPitch: Nullable.t<float>,
  mutable transition: Nullable.t<string>,
  mutable duration: Nullable.t<int>,
}

type scene = {
  id: string,
  mutable name: string,
  file: file,
  tinyFile: Nullable.t<file>,
  originalFile: Nullable.t<file>,
  mutable hotspots: array<hotspot>,
  mutable category: string,
  mutable floor: string,
  mutable label: string,
  mutable quality: Nullable.t<JSON.t>,
  mutable colorGroup: Nullable.t<string>,
  mutable _metadataSource: string,
  mutable categorySet: bool,
  mutable labelSet: bool,
  mutable isAutoForward: bool,
}

type timelineItem = {
  id: string,
  linkId: string,
  sceneId: string,
  targetScene: string,
  mutable transition: string,
  mutable duration: int,
}

type uploadReport = {
  success: array<string>,
  skipped: array<string>,
}

type state = {
  mutable tourName: string,
  mutable scenes: array<scene>,
  mutable activeIndex: int,
  mutable activeYaw: float,
  mutable activePitch: float,
  mutable isLinking: bool,
  mutable transition: transition,
  mutable lastUploadReport: uploadReport,
  mutable exifReport: Nullable.t<JSON.t>,
  mutable linkDraft: Nullable.t<linkDraft>,
  mutable preloadingSceneIndex: int,
  mutable isTeasing: bool,
  mutable deletedSceneIds: array<string>,
  mutable timeline: array<timelineItem>,
  mutable activeTimelineStepId: Nullable.t<string>,
}

// --- INITIAL STATE ---

let initialState = () => {
  tourName: "",
  scenes: [],
  activeIndex: -1,
  activeYaw: 0.0,
  activePitch: 0.0,
  isLinking: false,
  transition: {
    type_: Nullable.null,
    targetHotspotIndex: -1,
    fromSceneName: Nullable.null,
  },
  lastUploadReport: {
    success: [],
    skipped: [],
  },
  exifReport: Nullable.null,
  linkDraft: Nullable.null,
  preloadingSceneIndex: -1,
  isTeasing: false,
  deletedSceneIds: [],
  timeline: [],
  activeTimelineStepId: Nullable.null,
}

// --- STORE DATA ---

let internalState = ref(initialState())
let listeners = ref([])

let notify = () => {
  Belt.Array.forEach(listeners.contents, cb => cb(internalState.contents))
}

let subscribe = cb => {
  let _ = Array.push(listeners.contents, cb)
}

let syncSceneNames = () => {
  let renameMap = Dict.make()
  
  Belt.Array.forEachWithIndex(internalState.contents.scenes, (index, scene) => {
    if scene.label != "" {
      let oldName = scene.name
      let newName = TourLogic.computeSceneFilename(index, scene.label)
      if newName != oldName {
        Dict.set(renameMap, oldName, newName)
        scene.name = newName
      }
    }
  })
  
  if Belt.Array.length(Dict.keysToArray(renameMap)) > 0 {
    Belt.Array.forEach(internalState.contents.scenes, s => {
      Belt.Array.forEach(s.hotspots, h => {
        switch Dict.get(renameMap, h.target) {
        | Some(newName) => h.target = newName
        | None => ()
        }
      })
    })
  }
}

let applyLazyRename = (sceneIndex, newLabel) => {
  switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
  | Some(scene) =>
    let cleanLabel = String.trim(newLabel)
    scene.label = cleanLabel
    if cleanLabel != "" {
      scene.labelSet = true
    }
    syncSceneNames()
  | None => ()
  }
}

let addToTimeline = (~item: JSON.t, ~silent=false, ()) => {
  let i = (Obj.magic(item): {..})
  let timelineItem = {
    id: "seq_" ++ Float.toString(Date.now()) ++ "_" ++ Belt.Int.toString(Math.Int.floor(Math.random() *. 1000.0)),
    linkId: i["linkId"],
    sceneId: i["sceneId"],
    targetScene: i["targetScene"],
    transition: i["transition"],
    duration: i["duration"],
  }
  let _ = Array.push(internalState.contents.timeline, timelineItem)
  if !silent {
    notify()
  }
}

let reset = () => {
  internalState.contents = initialState()
  notify()
}

let setActiveScene = (~index, ~startYaw=0.0, ~startPitch=0.0, ~transition=?, ()) => {
  if index >= 0 && index < Belt.Array.length(internalState.contents.scenes) {
    let finalYaw = ref(startYaw)
    let finalPitch = ref(startPitch)
    
    switch Belt.Array.get(internalState.contents.scenes, index) {
    | Some(targetScene) =>
      if Belt.Option.isNone(transition) && startYaw == 0.0 && startPitch == 0.0 && Belt.Array.length(targetScene.hotspots) > 0 {
        let firstLink = Belt.Array.getBy(targetScene.hotspots, h => h.target != "")
        switch firstLink {
        | Some(link) =>
          if index == 0 {
            finalYaw.contents = link.yaw
            finalPitch.contents = link.pitch
          } else {
            finalYaw.contents = switch Nullable.toOption(link.startYaw) {
            | Some(y) => y
            | None => link.yaw
            }
            finalPitch.contents = switch Nullable.toOption(link.startPitch) {
            | Some(p) => p
            | None => link.pitch
            }
          }
        | None => ()
        }
      }

      internalState.contents.activeIndex = index
      internalState.contents.activeYaw = finalYaw.contents
      internalState.contents.activePitch = finalPitch.contents
      internalState.contents.transition = switch transition {
      | Some(t) => t
      | None => {type_: Nullable.null, targetHotspotIndex: -1, fromSceneName: Nullable.null}
      }
      notify()
    | None => ()
    }
  }
}

// Helper for array insertion
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
}

// --- MAIN STORE OBJECT ---

type store = {
  mutable state: state,
  notify: unit => unit,
  subscribe: (state => unit) => unit,
  setPreloadingScene: int => unit,
  setLinkDraft: Nullable.t<linkDraft> => unit,
  setIsTeasing: bool => unit,
  setTourName: string => unit,
  addScenes: array<JSON.t> => unit,
  setActiveScene: (~index: int, ~startYaw: float=?, ~startPitch: float=?, ~transition: transition=?, unit) => unit,
  addHotspot: (~sceneIndex: int, ~hotspotData: hotspot, ~skipNotify: bool=?, unit) => unit,
  removeHotspot: (int, int) => unit,
  reorderScenes: (int, int) => unit,
  clearHotspots: int => unit,
  deleteScene: int => unit,
  removeDeletedSceneId: string => unit,
  syncSceneNames: unit => unit,
  applyLazyRename: (int, string) => unit,
  updateSceneMetadata: (int, JSON.t) => unit,
  updateHotspotTargetView: (~sceneIndex: int, ~hotspotIndex: int, ~yaw: float, ~pitch: float, ~hfov: float, ~silent: bool=?, unit) => unit,
  updateHotspotReturnView: (~sceneIndex: int, ~hotspotIndex: int, ~yaw: float, ~pitch: float, ~hfov: float, ~silent: bool=?, unit) => unit,
  addToTimeline: (~item: JSON.t, ~silent: bool=?, unit) => unit,
  setActiveTimelineStep: Nullable.t<string> => unit,
  removeFromTimeline: string => unit,
  reorderTimeline: (int, int) => unit,
  updateTimelineStep: (string, JSON.t) => unit,
  getScenesByFloor: unit => Dict.t<array<JSON.t>>,
  loadProject: JSON.t => unit,
  reset: unit => unit,
}

let store = {
  state: internalState.contents,
  notify: notify,
  subscribe: subscribe,
  
  setPreloadingScene: index => {
    if internalState.contents.preloadingSceneIndex != index {
      internalState.contents.preloadingSceneIndex = index
      notify()
    }
  },

  setLinkDraft: draft => {
    internalState.contents.linkDraft = draft
    notify()
  },

  setIsTeasing: val => {
    if internalState.contents.isTeasing != val {
      internalState.contents.isTeasing = val
    }
  },

  setTourName: name => {
    let sanitized = TourLogic.sanitizeName(name, ~maxLength=100)
    if internalState.contents.tourName != sanitized {
      ReBindings.Debug.info("Store", "setTourName changed", ~data=sanitized, ())
      internalState.contents.tourName = sanitized
      notify()
    }
  },

  addScenes: (sceneDataList: array<JSON.t>) => {
    let success = []
    let skipped = []

    Belt.Array.forEach(sceneDataList, dataJson => {
      let data = (Obj.magic(dataJson): {..})
      let id = data["id"]
      let isDuplicate = Belt.Array.some(internalState.contents.scenes, s => s.id == id)
      if isDuplicate {
        let _ = Array.push(skipped, data["originalName"])
      } else {
        let newScene = {
          id: id,
          name: data["name"],
          file: data["preview"],
          tinyFile: Nullable.fromOption(Some(data["tiny"])),
          originalFile: Nullable.fromOption(Some(data["original"])),
          hotspots: [],
          category: "indoor",
          floor: "ground",
          label: "",
          quality: Nullable.fromOption(Some(data["quality"])),
          colorGroup: Nullable.fromOption(Some(data["colorGroup"])),
          _metadataSource: "default",
          categorySet: false,
          labelSet: false,
          isAutoForward: false,
        }
        let _ = Array.push(internalState.contents.scenes, newScene)
        let _ = Array.push(success, data["originalName"])
      }
    })

    let _ = Js.Array.sortInPlaceWith((a, b) => {
      Float.toInt(String.localeCompare(a.name, b.name))
    }, internalState.contents.scenes)

    if (internalState.contents.activeIndex == -1 || internalState.contents.activeIndex >= Belt.Array.length(internalState.contents.scenes)) && Belt.Array.length(internalState.contents.scenes) > 0 {
      internalState.contents.activeIndex = 0
      internalState.contents.activeYaw = 0.0
      internalState.contents.activePitch = 0.0
    }

    internalState.contents.lastUploadReport = {success: success, skipped: skipped}
    syncSceneNames()
    notify()
  },

  setActiveScene: setActiveScene,

  addHotspot: (~sceneIndex, ~hotspotData, ~skipNotify=false, ()) => {
    switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
    | Some(scene) =>
      if hotspotData.linkId == "" {
        let usedIds = Belt.Set.String.empty
        Belt.Array.forEach(internalState.contents.scenes, s => Belt.Array.forEach(s.hotspots, h => {
          if h.linkId != "" {
            let _ = Belt.Set.String.add(usedIds, h.linkId)
          }
        }))
        hotspotData.linkId = TourLogic.generateLinkId(usedIds)
      }
      let _ = Array.push(scene.hotspots, hotspotData)
      
      addToTimeline(
        ~item=(Obj.magic({
          "linkId": hotspotData.linkId,
          "sceneId": scene.id,
          "targetScene": hotspotData.target,
          "transition": "dissolve",
          "duration": 3000
        }): JSON.t),
        ~silent=true,
        ()
      )

      if !skipNotify {
        notify()
      }
    | None => ()
    }
  },

  removeHotspot: (sceneIndex, hotspotIndex) => {
    switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
    | Some(scene) =>
      let hotspot = Belt.Array.get(scene.hotspots, hotspotIndex)
      switch hotspot {
      | Some(h) =>
        let linkIdToRemove = h.linkId
        scene.hotspots = Belt.Array.keepWithIndex(scene.hotspots, (_, i) => i != hotspotIndex)
        
        if linkIdToRemove != "" {
          internalState.contents.timeline = Belt.Array.keep(internalState.contents.timeline, item =>
            !(item.sceneId == scene.id && item.linkId == linkIdToRemove)
          )
        }
        notify()
      | None => ()
      }
    | None => ()
    }
  },

  reorderScenes: (fromIndex, toIndex) => {
    if fromIndex != toIndex {
      let scenes = internalState.contents.scenes
      switch Belt.Array.get(scenes, fromIndex) {
      | Some(movedItem) =>
        let rest = Belt.Array.keepWithIndex(scenes, (_, i) => i != fromIndex)
        internalState.contents.scenes = insertAt(rest, toIndex, movedItem)
        
        if internalState.contents.activeIndex == fromIndex {
          internalState.contents.activeIndex = toIndex
        } else if internalState.contents.activeIndex > fromIndex && internalState.contents.activeIndex <= toIndex {
          internalState.contents.activeIndex = internalState.contents.activeIndex - 1
        } else if internalState.contents.activeIndex < fromIndex && internalState.contents.activeIndex >= toIndex {
          internalState.contents.activeIndex = internalState.contents.activeIndex + 1
        }
        
        syncSceneNames()
        notify()
      | None => ()
      }
    }
  },

  clearHotspots: sceneIndex => {
    switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
    | Some(scene) =>
      scene.hotspots = []
      notify()
    | None => ()
    }
  },

  deleteScene: index => {
    switch Belt.Array.get(internalState.contents.scenes, index) {
    | Some(sceneToDelete) =>
      let targetName = sceneToDelete.name
      
      Belt.Array.forEach(internalState.contents.scenes, scene => {
        scene.hotspots = Belt.Array.keep(scene.hotspots, h => h.target != targetName)
      })
      
      if sceneToDelete.id != "" {
        if !(Belt.Array.some(internalState.contents.deletedSceneIds, id => id == sceneToDelete.id)) {
          let _ = Array.push(internalState.contents.deletedSceneIds, sceneToDelete.id)
        }
        internalState.contents.timeline = Belt.Array.keep(internalState.contents.timeline, item => item.sceneId != sceneToDelete.id)
      }
      
      internalState.contents.scenes = Belt.Array.keepWithIndex(internalState.contents.scenes, (_, i) => i != index)
      
      let newLen = Belt.Array.length(internalState.contents.scenes)
      if newLen == 0 {
        internalState.contents.activeIndex = -1
      } else if index == internalState.contents.activeIndex {
        let nextIndex = if index < newLen { index } else { newLen - 1 }
        setActiveScene(~index=nextIndex, ~startYaw=0.0, ~startPitch=0.0, ())
      } else if index < internalState.contents.activeIndex {
        internalState.contents.activeIndex = internalState.contents.activeIndex - 1
      }
      
      syncSceneNames()
      notify()
    | None => ()
    }
  },

  removeDeletedSceneId: id => {
    internalState.contents.deletedSceneIds = Belt.Array.keep(internalState.contents.deletedSceneIds, d => d != id)
  },

  syncSceneNames: syncSceneNames,
  applyLazyRename: applyLazyRename,

  updateSceneMetadata: (sceneIndex, metadataJson) => {
    switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
    | Some(scene) =>
      let meta = (Obj.magic(metadataJson): {..})
      
      switch Nullable.toOption(meta["category"]) {
      | Some(cat) => 
          scene.category = cat
          scene.categorySet = true
      | None => ()
      }
      
      switch Nullable.toOption(meta["floor"]) {
      | Some(fl) => 
          scene.floor = fl
          scene._metadataSource = "user"
      | None => ()
      }
      
      switch Nullable.toOption(meta["label"]) {
      | Some(lb) => applyLazyRename(sceneIndex, lb)
      | None => ()
      }
      
      switch Nullable.toOption(meta["isAutoForward"]) {
      | Some(af) => scene.isAutoForward = af
      | None => ()
      }
      
      notify()
    | None => ()
    }
  },

  updateHotspotTargetView: (~sceneIndex, ~hotspotIndex, ~yaw, ~pitch, ~hfov, ~silent=true, ()) => {
    switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
    | Some(scene) =>
      switch Belt.Array.get(scene.hotspots, hotspotIndex) {
      | Some(hotspot) =>
        hotspot.targetYaw = Nullable.fromOption(Some(yaw))
        hotspot.targetPitch = Nullable.fromOption(Some(pitch))
        hotspot.targetHfov = Nullable.fromOption(Some(hfov))
        if !silent {
          notify()
        }
      | None => ()
      }
    | None => ()
    }
  },

  updateHotspotReturnView: (~sceneIndex, ~hotspotIndex, ~yaw, ~pitch, ~hfov, ~silent=true, ()) => {
    switch Belt.Array.get(internalState.contents.scenes, sceneIndex) {
    | Some(scene) =>
      switch Belt.Array.get(scene.hotspots, hotspotIndex) {
      | Some(hotspot) =>
        switch Nullable.toOption(hotspot.returnViewFrame) {
        | Some(_rvf) =>
           let updatedRvf = {yaw: yaw, pitch: pitch, hfov: hfov}
           hotspot.returnViewFrame = Nullable.fromOption(Some(updatedRvf))
        | None => ()
        }
        if !silent {
          notify()
        }
      | None => ()
      }
    | None => ()
    }
  },

  addToTimeline: addToTimeline,

  setActiveTimelineStep: id => {
    if internalState.contents.activeTimelineStepId != id {
      internalState.contents.activeTimelineStepId = id
      notify()
    }
  },

  removeFromTimeline: id => {
    internalState.contents.timeline = Belt.Array.keep(internalState.contents.timeline, item => item.id != id)
    notify()
  },

  reorderTimeline: (fromIndex, toIndex) => {
    if fromIndex != toIndex {
      let list = internalState.contents.timeline
      switch Belt.Array.get(list, fromIndex) {
      | Some(moved) =>
        let rest = Belt.Array.keepWithIndex(list, (_, i) => i != fromIndex)
        internalState.contents.timeline = insertAt(rest, toIndex, moved)
        notify()
      | None => ()
      }
    }
  },

  updateTimelineStep: (id, changesJson) => {
    let item = Belt.Array.getBy(internalState.contents.timeline, i => i.id == id)
    switch item {
    | Some(i) =>
       let c = (Obj.magic(changesJson): {..})
       switch Nullable.toOption(c["transition"]) {
       | Some(tr) => i.transition = tr
       | None => ()
       }
       switch Nullable.toOption(c["duration"]) {
       | Some(du) => i.duration = du
       | None => ()
       }
       notify()
    | None => ()
    }
  },

  getScenesByFloor: () => {
    let grouped = Dict.make()
    Belt.Array.forEachWithIndex(internalState.contents.scenes, (index, scene) => {
      let floor = if scene.floor == "" { "ground" } else { scene.floor }
      let list = switch Dict.get(grouped, floor) {
      | Some(l) => l
      | None => {
          let nl = []
          Dict.set(grouped, floor, nl)
          nl
        }
      }
      let _ = Array.push(list, (Obj.magic({"scene": scene, "index": index}): JSON.t))
    })
    grouped
  },

  loadProject: projectDataJson => {
    try {
        reset()
        
        let pd = (Obj.magic(projectDataJson): {..})
        internalState.contents.tourName = switch Nullable.toOption(pd["tourName"]) {
        | Some(tn) => tn
        | None => "Imported Tour"
        }
        
        let scenesArrJson = (pd["scenes"]: JSON.t)
        if Array.isArray(scenesArrJson) {
            let scenesArr = (Obj.magic(scenesArrJson): array<JSON.t>)
            internalState.contents.scenes = Belt.Array.map(scenesArr, sJson => {
                let sc = (Obj.magic(sJson): {..})
                {
                  id: switch Nullable.toOption(sc["id"]) { | Some(id) => id | None => "legacy_" ++ sc["name"] },
                  name: sc["name"],
                  file: sc["file"],
                  tinyFile: Nullable.fromOption(Nullable.toOption(sc["tinyFile"])),
                  originalFile: Nullable.fromOption(Nullable.toOption(sc["originalFile"])),
                  hotspots: switch Nullable.toOption(sc["hotspots"]) {
                  | Some(hssJson) => 
                       if Array.isArray(hssJson) {
                           let hss = (Obj.magic(hssJson): array<JSON.t>)
                           Belt.Array.map(hss, hJson => {
                              let hs = (Obj.magic(hJson): {..})
                              {
                                linkId: switch Nullable.toOption(hs["linkId"]) { | Some(id) => id | None => "" },
                                yaw: hs["yaw"],
                                pitch: hs["pitch"],
                                target: hs["target"],
                                targetYaw: Nullable.fromOption(Nullable.toOption(hs["targetYaw"])),
                                targetPitch: Nullable.fromOption(Nullable.toOption(hs["targetPitch"])),
                                targetHfov: Nullable.fromOption(Nullable.toOption(hs["targetHfov"])),
                                startYaw: Nullable.fromOption(Nullable.toOption(hs["startYaw"])),
                                startPitch: Nullable.fromOption(Nullable.toOption(hs["startPitch"])),
                                startHfov: Nullable.fromOption(Nullable.toOption(hs["startHfov"])),
                                isReturnLink: Nullable.fromOption(Nullable.toOption(hs["isReturnLink"])),
                                viewFrame: Nullable.fromOption(Nullable.toOption(hs["viewFrame"])),
                                returnViewFrame: Nullable.fromOption(Nullable.toOption(hs["returnViewFrame"])),
                                waypoints: Nullable.fromOption(Nullable.toOption(hs["waypoints"])),
                                displayPitch: Nullable.fromOption(Nullable.toOption(hs["displayPitch"])),
                                transition: Nullable.fromOption(Nullable.toOption(hs["transition"])),
                                duration: Nullable.fromOption(Nullable.toOption(hs["duration"])),
                              }
                           })
                       } else { [] }
                  | None => []
                  },
                  category: switch Nullable.toOption(sc["category"]) { | Some(c) => c | None => "indoor" },
                  floor: switch Nullable.toOption(sc["floor"]) { | Some(f) => f | None => "ground" },
                  label: switch Nullable.toOption(sc["label"]) { | Some(l) => l | None => "" },
                  quality: Nullable.fromOption(Nullable.toOption(sc["quality"])),
                  colorGroup: Nullable.fromOption(Nullable.toOption(sc["colorGroup"])),
                  _metadataSource: switch Nullable.toOption(sc["_metadataSource"]) { | Some(m) => m | None => "user" },
                  categorySet: switch Nullable.toOption(sc["categorySet"]) { | Some(cs) => cs | None => false },
                  labelSet: switch Nullable.toOption(sc["labelSet"]) { | Some(ls) => ls | None => false },
                  isAutoForward: switch Nullable.toOption(sc["isAutoForward"]) { | Some(af) => af | None => false },
                }
            })
        }
        
        let pdTimeline = Nullable.toOption(pd["timeline"])
        switch pdTimeline {
        | Some(tl) =>
            if Array.isArray(tl) {
                internalState.contents.timeline = (Obj.magic(tl): array<timelineItem>)
            }
        | None => ()
        }
        
        let usedIds = Belt.Set.String.empty
        Belt.Array.forEach(internalState.contents.scenes, s => Belt.Array.forEach(s.hotspots, h => {
          if h.linkId != "" {
            let _ = Belt.Set.String.add(usedIds, h.linkId)
          }
        }))
        
        Belt.Array.forEach(internalState.contents.scenes, s => {
          Belt.Array.forEach(s.hotspots, h => {
            if h.linkId == "" {
              h.linkId = TourLogic.generateLinkId(usedIds)
              let _ = Belt.Set.String.add(usedIds, h.linkId)
            }
            
            let existsInTimeline = Belt.Array.some(internalState.contents.timeline, item =>
              item.sceneId == s.id && item.linkId == h.linkId
            )
            
            if !existsInTimeline {
              addToTimeline(
                ~item=(Obj.magic({
                  "linkId": h.linkId,
                  "sceneId": s.id,
                  "targetScene": h.target,
                  "transition": switch Nullable.toOption(h.transition) { | Some(t) => t | None => "dissolve" },
                  "duration": switch Nullable.toOption(h.duration) { | Some(d) => d | None => 3000 }
                }): JSON.t),
                ~silent=true,
                ()
              )
            }
          })
        })
        
        if Belt.Array.length(internalState.contents.scenes) > 0 {
           let targetIdx = switch Nullable.toOption(pd["activeIndex"]) {
           | Some(idx) => if idx >= 0 && idx < Belt.Array.length(internalState.contents.scenes) { idx } else { 0 }
           | None => 0
           }
           setActiveScene(~index=targetIdx, ~startYaw=0.0, ~startPitch=0.0, ())
        }

        notify()
    } catch {
    | JsExn(obj) => 
        let m = switch JsExn.message(obj) { | Some(msg) => msg | None => "Unknown exception" }
        ReBindings.Debug.error("Store", "loadProject failed: " ++ m, ())
        %raw(`(() => { throw obj })()`)
    | _ => 
        ReBindings.Debug.error("Store", "loadProject unknown failure", ())
        %raw(`(() => { throw new Error("Store: Unknown failure") })()`)
    }
  },

  reset: reset,
}
