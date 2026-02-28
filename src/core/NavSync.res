/* src/core/NavSync.res */

open Types

let syncNavigationFsm = (nextState: state): state => {
  switch nextState.appMode {
  | Interactive(s) => {
      ...nextState,
      navigationState: {...nextState.navigationState, navigationFsm: s.navigation},
    }
  | _ => nextState
  }
}

let syncNavigationFsmInAppMode = (nextState: state, nextNavState: navigationState): state => {
  switch nextState.appMode {
  | Interactive(s) => {
      ...nextState,
      appMode: Interactive({...s, navigation: nextNavState.navigationFsm}),
    }
  | _ => nextState
  }
}
