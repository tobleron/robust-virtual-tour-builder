// @efficiency-role: ui-component
open ReBindings

type adminIcon =
  | AddIcon
  | UploadIcon
  | SettingsIcon
  | DetailIcon
  | CopyIcon
  | CheckIcon
  | OpenIcon
  | PublishIcon
  | DraftIcon
  | ArchiveIcon
  | DeleteIcon
  | SaveIcon
  | LinkIcon
  | RevokeIcon

let messageNode = (~flash: PortalAppCore.flash) => <>
  {switch flash.error {
  | Some(message) => <div className="portal-message is-error"> {React.string(message)} </div>
  | None => React.null
  }}
  {switch flash.success {
  | Some(message) => <div className="portal-message is-success"> {React.string(message)} </div>
  | None => React.null
  }}
</>

let brandLockup = (~title="ROBUST", ()) =>
  <span className="portal-brand-mark">
    <svg viewBox="0 0 24 24" fill="none" ariaHidden=true>
      <path
        d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" stroke="currentColor" strokeWidth="2"
      />
      <path d="M9 22V12h6v10" stroke="currentColor" strokeWidth="2" />
    </svg>
    <span> {React.string(title)} </span>
  </span>

let appBrandHeader = () =>
  <div className="portal-brand-stack">
    <span className="portal-brand-logo-lockup">
      <img
        className="portal-brand-logo" src="/images/logo.webp" alt="Robust Virtual Tour Builder logo"
      />
      <span className="portal-brand-product"> {React.string("Robust Virtual Tour Builder")} </span>
    </span>
  </div>

let adminActionIcon = icon =>
  <span className="portal-action-icon" ariaHidden=true>
    <svg viewBox="0 0 24 24" fill="none">
      {switch icon {
      | AddIcon =>
        <>
          <path d="M12 5v14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M5 12h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | UploadIcon =>
        <>
          <path
            d="M12 15V5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="m8 9 4-4 4 4"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M5 19h14"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | SettingsIcon =>
        <>
          <path
            d="M12 8.5A3.5 3.5 0 1 0 12 15.5A3.5 3.5 0 1 0 12 8.5Z"
            stroke="currentColor"
            strokeWidth="2"
          />
          <path
            d="M19 12a7 7 0 0 0-.08-1l2.03-1.58-2-3.46-2.43.73a7.08 7.08 0 0 0-1.72-1l-.43-2.5h-4l-.43 2.5a7.08 7.08 0 0 0-1.72 1l-2.43-.73-2 3.46L5.08 11a7 7 0 0 0 0 2l-2.03 1.58 2 3.46 2.43-.73a7.08 7.08 0 0 0 1.72 1l.43 2.5h4l.43-2.5a7.08 7.08 0 0 0 1.72-1l2.43.73 2-3.46L18.92 13c.05-.33.08-.66.08-1Z"
            stroke="currentColor"
            strokeWidth="1.7"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | DetailIcon =>
        <>
          <path
            d="M4 12h16"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="m13 5 7 7-7 7"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | CopyIcon =>
        <>
          <rect x="9" y="9" width="10" height="10" rx="2" stroke="currentColor" strokeWidth="2" />
          <path
            d="M7 15H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v1"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | CheckIcon =>
        <>
          <path
            d="M6.5 12.5 10.2 16.2 17.5 8.9"
            stroke="currentColor"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | OpenIcon =>
        <>
          <path
            d="M14 5h5v5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="m10 14 9-9"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M19 14v3a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h3"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | PublishIcon =>
        <>
          <path
            d="M7 13.5 10.5 17 17 8"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | DraftIcon =>
        <>
          <path d="M6 5h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M6 12h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M6 19h8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | ArchiveIcon =>
        <>
          <path
            d="M4 7h16"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M6 7h12v10a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2Z"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinejoin="round"
          />
          <path d="M10 11h4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | DeleteIcon =>
        <>
          <path d="M5 7h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path
            d="M9 7V5h6v2"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M8 7v11a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V7"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinejoin="round"
          />
          <path d="M10 11v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M14 11v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | SaveIcon =>
        <>
          <path
            d="M5 5h11l3 3v11H5Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"
          />
          <path d="M8 5v5h7" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
          <path d="M9 19v-5h6v5" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
        </>
      | LinkIcon =>
        <>
          <path
            d="M10.5 13.5 13.5 10.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round"
          />
          <path
            d="M8.5 15.5H7a4 4 0 1 1 0-8h1.5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M15.5 8.5H17a4 4 0 1 1 0 8h-1.5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | RevokeIcon =>
        <>
          <path d="M8 8 16 16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="m16 8-8 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
        </>
      }}
    </svg>
  </span>

let actionLabel = (~icon, ~label) => <>
  {adminActionIcon(icon)}
  <span> {React.string(label)} </span>
</>

module CopyActionButton = {
  @react.component
  let make = (
    ~url,
    ~className,
    ~ariaLabel,
    ~title,
    ~label="Copy",
    ~copiedLabel="Copied",
    ~disabled=false,
    ~iconOnly=false,
    ~onCopyError: option<string => unit>=?,
  ) => {
    let (isCopied, setIsCopied) = React.useState(() => false)
    let timeoutRef: React.ref<option<int>> = React.useRef(None)

    React.useEffect0(() => {
      Some(() => timeoutRef.current->Option.forEach(id => Window.clearTimeout(id)))
    })

    let handleClick = _ =>
      if !disabled {
        ignore(
          (
            async () => {
              try {
                let _ = await Clipboard.writeText(url)
                timeoutRef.current->Option.forEach(id => Window.clearTimeout(id))
                setIsCopied(_ => true)
                let timeoutId = Window.setTimeout(() => {
                  timeoutRef.current = None
                  setIsCopied(_ => false)
                }, 1600)
                timeoutRef.current = Some(timeoutId)
              } catch {
              | _ =>
                onCopyError->Option.forEach(report => report("Unable to copy link automatically."))
              }
            }
          )(),
        )
      }

    let icon = if isCopied {
      CheckIcon
    } else {
      CopyIcon
    }
    let resolvedLabel = if isCopied {
      copiedLabel
    } else {
      label
    }
    let resolvedTitle = if isCopied {
      copiedLabel
    } else {
      title
    }
    <button
      className={className ++ if isCopied {
        " is-copied"
      } else {
        ""
      }}
      disabled={disabled}
      ariaLabel
      title={resolvedTitle}
      onClick={handleClick}
    >
      {if iconOnly {
        adminActionIcon(icon)
      } else {
        actionLabel(~icon, ~label=resolvedLabel)
      }}
    </button>
  }
}

let mobileLabel = label => <small className="portal-mobile-label"> {React.string(label)} </small>
