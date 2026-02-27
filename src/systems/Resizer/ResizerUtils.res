/* src/systems/Resizer/ResizerUtils.res */

open ReBindings

let formatBytesToMB = (v: float): string => {
  Float.toFixed(v /. 1024.0 /. 1024.0, ~digits=0) ++ "MB"
}

let safeGetMemoryStats = (): option<(float, float, float)> => {
  %raw(`
    (function() {
      if (typeof window !== 'undefined' && window.performance && window.performance.memory) {
         const mem = window.performance.memory;
         return [mem.usedJSHeapSize, mem.totalJSHeapSize, mem.jsHeapSizeLimit];
      }
      return undefined;
    })()
  `)
}

let getMemoryUsage = () => {
  switch safeGetMemoryStats() {
  | Some((u, t, l)) => {
      "used": formatBytesToMB(u),
      "total": formatBytesToMB(t),
      "limit": formatBytesToMB(l),
    }
  | None => {"used": "N/A", "total": "N/A", "limit": "N/A"}
  }
}

let getChecksum = (file: File.t): Promise.t<string> => {
  let internalGetChecksum: File.t => Promise.t<string> = %raw(`
     async function(file) {
        const SMALL_FILE_THRESHOLD = 10 * 1024 * 1024;
        const SAMPLE_SIZE = 1024 * 1024;
        let hashBuffer;
        
        if (typeof crypto === 'undefined' || !crypto.subtle) {
            console.warn('[ResizerUtils] crypto.subtle is unavailable. Using weak fallback for fingerprinting.');
            const simpleHash = (s) => {
                let h = 0;
                for(let i = 0; i < s.length; i++) h = Math.imul(31, h) + s.charCodeAt(i) | 0;
                return Math.abs(h).toString(16);
            };
            const meta = file.name + "_" + file.size + "_" + file.lastModified;
            return "weak_" + simpleHash(meta) + "_" + file.size;
        }

        if (file.size <= SMALL_FILE_THRESHOLD) {
            const arrayBuffer = await file.arrayBuffer();
            hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
        } else {
            const samples = [
                file.slice(0, SAMPLE_SIZE),
                file.slice(Math.floor(file.size / 2), Math.floor(file.size / 2) + SAMPLE_SIZE),
                file.slice(Math.max(0, file.size - SAMPLE_SIZE), file.size)
            ];
            const sampleBuffers = await Promise.all(samples.map(s => s.arrayBuffer()));
            const totalSize = sampleBuffers.reduce((acc, buf) => acc + buf.byteLength, 0);
            const combined = new Uint8Array(totalSize);
            let offset = 0;
            sampleBuffers.forEach(buf => { combined.set(new Uint8Array(buf), offset); offset += buf.byteLength; });
            hashBuffer = await crypto.subtle.digest('SHA-256', combined);
        }
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        return hash + "_" + file.size;
     }
   `)
  internalGetChecksum(file)
}

let checkBackendHealth = () => {
  let controller = AbortController.make()
  let signal = AbortController.signal(controller)
  let requestUrl = Constants.backendUrl ++ "/health?t=" ++ Date.now()->Float.toString
  // Health checks should fail fast to avoid blocking upload start.
  let timeoutId = Window.setTimeout(() => AbortController.abort(controller), 5000)

  Logger.debug(~module_="Resizer", ~message="CHECKING_HEALTH", ~data=Some({"url": requestUrl}), ())

  RequestQueue.scheduleWithRetry(
    ~task=() => {
      Fetch.fetch(requestUrl, Fetch.requestInit(~method="GET", ~signal, ()))
      ->Promise.then(res => {
        let status = Fetch.status(res)
        if Fetch.ok(res) {
          Promise.resolve(Ok(true))
        } else if status == 429 || status == 408 || status >= 500 {
          Promise.resolve(
            Error(
              "HttpError: Status " ++ Belt.Int.toString(status) ++ " - " ++ Fetch.statusText(res),
            ),
          )
        } else {
          Logger.warn(
            ~module_="Resizer",
            ~message="HEALTH_CHECK_FAILED_NON_RETRYABLE",
            ~data={
              "status": status,
              "statusText": Fetch.statusText(res),
              "url": Constants.backendUrl ++ "/health",
            },
            (),
          )
          Promise.resolve(Ok(false))
        }
      })
      ->Promise.catch(err => {
        let (msg, _) = Logger.getErrorDetails(err)
        Promise.resolve(Error(msg))
      })
    },
    ~signal,
    ~retryConfig={
      maxRetries: 2,
      initialDelayMs: 150,
      maxDelayMs: 1200,
      backoffMultiplier: 2.0,
      jitter: true,
      totalDeadlineMs: 5000,
    },
    ~onRetry=(attempt, error, delayMs) => {
      Logger.warn(
        ~module_="Resizer",
        ~message="HEALTH_CHECK_RETRY",
        ~data=Some({
          "attempt": attempt,
          "error": error,
          "nextDelayMs": delayMs,
        }),
        (),
      )
    },
  )
  ->Promise.then(result => {
    Window.clearTimeout(timeoutId)
    switch result {
    | Retry.Success(isHealthy, _) => Promise.resolve(isHealthy)
    | Retry.Exhausted(msg) =>
      Logger.warn(
        ~module_="Resizer",
        ~message="HEALTH_CHECK_EXHAUSTED",
        ~data=Some({"error": msg, "url": Constants.backendUrl ++ "/health"}),
        (),
      )
      Promise.resolve(false)
    }
  })
  ->Promise.catch(_ => {
    Window.clearTimeout(timeoutId)
    Promise.resolve(false)
  })
}
