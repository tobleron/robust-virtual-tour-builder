include OperationLifecycleTypes

let matchesBusyFilter = (task, ~type_, ~scope): bool => {
  let isActive = OperationLifecycleContext.isActiveStatus(task.status)

  let typeMatch = switch type_ {
  | Some(t) => task.type_ == t
  | None => true
  }

  let scopeMatch = switch scope {
  | Some(s) => task.scope == s
  | None => true
  }

  isActive && typeMatch && scopeMatch
}

let isBusy = (~operations, ~type_, ~scope, ()): bool => {
  operations.contents->Belt.Map.String.some((_, task) => matchesBusyFilter(task, ~type_, ~scope))
}

let arrayIsBusy = (~ops, ~type_, ~scope): bool => {
  ops->Belt.Array.some(task => matchesBusyFilter(task, ~type_, ~scope))
}
