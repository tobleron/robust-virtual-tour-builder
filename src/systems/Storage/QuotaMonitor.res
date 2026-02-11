/* src/systems/Storage/QuotaMonitor.res */

open StorageBindings

let warningThreshold = 0.80 // 80%
let criticalThreshold = 0.95 // 95%

let checkQuota = async () => {
  try {
    let estimate = await StorageManager.estimate()
    let usagePercent = estimate.usage /. estimate.quota
    let percentStr = Float.toFixed(usagePercent *. 100.0, ~digits=1)

    if usagePercent > criticalThreshold {
      NotificationManager.dispatch({
        id: "",
        importance: NotificationTypes.Error,
        context: NotificationTypes.SystemEvent("storage"),
        message: "Storage critically full. Save your work and clear old projects.",
        details: Some("Usage: " ++ percentStr ++ "%"),
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(NotificationTypes.Error),
        dismissible: true,
        createdAt: Date.now(),
      })
    } else if usagePercent > warningThreshold {
      NotificationManager.dispatch({
        id: "",
        importance: NotificationTypes.Warning,
        context: NotificationTypes.SystemEvent("storage"),
        message: "Storage nearly full (" ++ percentStr ++ "%). Consider removing old projects.",
        details: Some("Usage: " ++ percentStr ++ "%"),
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(NotificationTypes.Warning),
        dismissible: true,
        createdAt: Date.now(),
      })
    }

    Logger.info(
      ~module_="QuotaMonitor",
      ~message="QUOTA_CHECK",
      ~data=Some(
        Logger.castToJson({
          "usageMB": estimate.usage /. 1048576.0,
          "quotaMB": estimate.quota /. 1048576.0,
          "percent": usagePercent *. 100.0,
        }),
      ),
      (),
    )
  } catch {
  | _ =>
    // StorageManager.estimate() is not available in all browsers
    Logger.debug(~module_="QuotaMonitor", ~message="STORAGE_API_UNAVAILABLE", ())
  }
}
