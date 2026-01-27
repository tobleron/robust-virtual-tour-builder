/* src/components/Sidebar/SidebarMainTypes.res */

type procState = {
  active: bool,
  progress: float,
  message: string,
  phase: string,
  error: bool,
}

type file = ReBindings.File.t

type processingPayload = {
  "active": bool,
  "progress": float,
  "message": string,
  "phase": string,
  "error": bool,
}
