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

// Helper to sleep for specified milliseconds
let sleep = (delayMs: int): Promise.t<unit> => {
  Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => {
      resolve()
    }, delayMs)
  })
}

let checkBackendHealth = () => {
  // Retry logic with exponential backoff (up to 3 attempts)
  let rec attemptHealthCheck = (~attempt=0, ~maxAttempts=3) => {
    let controller = AbortController.make()
    let _signal = AbortController.signal(controller)
    let timeoutId = Window.setTimeout(() => AbortController.abort(controller), 5000)
    let timestamp = Date.now()->Float.toString

    Logger.debug(
      ~module_="Resizer",
      ~message="CHECKING_HEALTH",
      ~data=Some({
        "url": Constants.backendUrl ++ "/health?t=" ++ timestamp,
        "attempt": attempt + 1,
      }),
      (),
    )

    RequestQueue.schedule(() => {
      Fetch.fetch(
        Constants.backendUrl ++ "/health?t=" ++ timestamp,
        Fetch.requestInit(~method="GET", ~signal=_signal, ()),
      )
    })
    ->Promise.then(res => {
      Window.clearTimeout(timeoutId)
      let status = Fetch.status(res)

      // Success (200 OK)
      if Fetch.ok(res) {
        Promise.resolve(true)
      } // Rate limited (429) - retry with backoff
      else if status == 429 && attempt < maxAttempts - 1 {
        Logger.warn(
          ~module_="Resizer",
          ~message="HEALTH_CHECK_RATE_LIMITED",
          ~data={
            "status": status,
            "attempt": attempt + 1,
            "retrying": true,
          },
          (),
        )
        // Exponential backoff: 100ms * 2^attempt
        let delayMs = 100.0 *. %raw(`Math.pow(2, attempt)`)
        let delayInt = Int.fromFloat(delayMs)
        sleep(delayInt)->Promise.then(() => attemptHealthCheck(~attempt=attempt + 1, ~maxAttempts))
      } else {
        // Other errors

        Logger.warn(
          ~module_="Resizer",
          ~message="HEALTH_CHECK_FAILED",
          ~data={
            "status": status,
            "statusText": Fetch.statusText(res),
            "url": Constants.backendUrl ++ "/health",
            "attempt": attempt + 1,
          },
          (),
        )
        Promise.resolve(Fetch.ok(res))
      }
    })
    ->Promise.catch(err => {
      Window.clearTimeout(timeoutId)
      let (msg, stack) = Logger.getErrorDetails(err)

      // Retry on network errors too
      if attempt < maxAttempts - 1 {
        Logger.warn(
          ~module_="Resizer",
          ~message="HEALTH_CHECK_NETWORK_ERROR",
          ~data={"error": msg, "attempt": attempt + 1, "retrying": true},
          (),
        )
        let delayMs = 100.0 *. %raw(`Math.pow(2, attempt)`)
        let delayInt = Int.fromFloat(delayMs)
        sleep(delayInt)->Promise.then(() => attemptHealthCheck(~attempt=attempt + 1, ~maxAttempts))
      } else {
        Logger.warn(
          ~module_="Resizer",
          ~message="HEALTH_CHECK_ERROR",
          ~data={
            "error": msg,
            "stack": stack,
            "url": Constants.backendUrl ++ "/health",
            "attempt": attempt + 1,
          },
          (),
        )
        Promise.resolve(false)
      }
    })
  }

  attemptHealthCheck()
}
