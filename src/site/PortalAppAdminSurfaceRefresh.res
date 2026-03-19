// @efficiency-role: ui-component
open PortalAppCore

type props = {
  setState: (remoteData<adminData> => remoteData<adminData>) => unit,
  setIsRefreshing: (bool => bool) => unit,
  setSelectedCustomerId: (option<string> => option<string>) => unit,
  setSelectedBulkCustomerIds: (Belt.Set.String.t => Belt.Set.String.t) => unit,
  setSelectedBulkTourIds: (Belt.Set.String.t => Belt.Set.String.t) => unit,
  setSettingsEdit: (option<settingsDraft> => option<settingsDraft>) => unit,
}

let make = (~props: props) => {
  let fetchAdminData = async (): adminRefreshResult => {
    let session = await PortalApi.getAdminSession()
    if !session.authenticated {
      RefreshAuth
    } else {
      switch await PortalApi.loadSettings() {
      | Error(message) => RefreshError(message)
      | Ok(settings) =>
        switch await PortalApi.listCustomers() {
        | Error(message) => RefreshError(message)
        | Ok(customers) =>
          switch await PortalApi.listLibraryTours() {
          | Error(message) => RefreshError(message)
          | Ok(tours) => RefreshOk({session, settings, customers, tours})
          }
        }
      }
    }
  }

  let retainSetItems = (items: Belt.Set.String.t, keepItem: string => bool) =>
    items
    ->Belt.Set.String.toArray
    ->Belt.Array.keep(keepItem)
    ->Belt.Array.reduce(Belt.Set.String.empty, (acc, item) => acc->Belt.Set.String.add(item))

  let nextSelectedCustomerId = (payload, prev: option<string>) =>
    switch prev {
    | Some(customerId)
      if payload.customers->Belt.Array.some(customer => customer.customer.id == customerId) =>
      Some(customerId)
    | _ => payload.customers->Belt.Array.get(0)->Option.map(customer => customer.customer.id)
    }

  let nextSelectedBulkCustomerIds = (payload, prev) =>
    retainSetItems(prev, customerId =>
      payload.customers->Belt.Array.some(customer => customer.customer.id == customerId)
    )

  let nextSelectedBulkTourIds = (payload, prev) =>
    retainSetItems(prev, tourId => payload.tours->Belt.Array.some(tour => tour.tour.id == tourId))

  let retainAdminSelections = payload => {
    props.setSelectedCustomerId(prev => nextSelectedCustomerId(payload, prev))
    props.setSelectedBulkCustomerIds(prev => nextSelectedBulkCustomerIds(payload, prev))
    props.setSelectedBulkTourIds(prev => nextSelectedBulkTourIds(payload, prev))
  }

  let applyAdminData = payload => {
    retainAdminSelections(payload)
    props.setSettingsEdit(_ => Some(draftFromSettings(payload.settings)))
    props.setState(_ => Ready(payload))
  }

  let loadAdmin = (~preserveReadyState=false) => {
    if preserveReadyState {
      props.setIsRefreshing(_ => true)
    } else {
      props.setState(_ => Loading)
    }
    ignore(
      (
        async () => {
          switch await fetchAdminData() {
          | RefreshAuth => props.setState(_ => Failed("AUTH"))
          | RefreshError(message) => props.setState(_ => Failed(message))
          | RefreshOk(payload) => applyAdminData(payload)
          }
          props.setIsRefreshing(_ => false)
        }
      )(),
    )
  }

  loadAdmin
}
