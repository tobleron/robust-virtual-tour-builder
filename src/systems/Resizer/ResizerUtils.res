/* src/systems/Resizer/ResizerUtils.res */

open ReBindings

let weakFingerprintFallbackLogged = ref(false)

let isCryptoSubtleAvailableInCurrentContext = (): bool =>
  %raw(`
    (function() {
      try {
        return typeof crypto !== 'undefined' &&
          !!crypto &&
          !!crypto.subtle &&
          (typeof window === 'undefined' || window.isSecureContext === true);
      } catch (_err) {
        return false;
      }
    })()
  `)

let logWeakChecksumFallbackOnce = () => {
  if !weakFingerprintFallbackLogged.contents {
    weakFingerprintFallbackLogged := true
    Logger.warn(
      ~module_="ResizerUtils",
      ~message="STRONG_FINGERPRINT_UNAVAILABLE_USING_WEAK_FINGERPRINT_FALLBACK",
      ~data=Some({
        "reason": "crypto.subtle unavailable in current browser context",
        "hint": "Use HTTPS or localhost to restore SHA-256 fingerprinting",
      }),
      (),
    )
  }
}

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
  let internalGetChecksum: (File.t, unit => unit) => Promise.t<string> = %raw(`
     async function(file, logWeakChecksumFallback) {
        const SMALL_FILE_THRESHOLD = 10 * 1024 * 1024;
        const SAMPLE_SIZE = 1024 * 1024;
        let hashBuffer;
        
        if (typeof crypto === 'undefined' || !crypto.subtle) {
            logWeakChecksumFallback();
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
  internalGetChecksum(file, logWeakChecksumFallbackOnce)
}

let checkBackendHealth = () => {
  let controller = AbortController.make()
  let signal = AbortController.signal(controller)
  let requestUrl = Constants.backendUrl ++ "/health?t=" ++ Date.now()->Float.toString
  let timeoutMs = 5000
  // Health checks should fail fast to avoid blocking upload start.
  let timeoutId = Window.setTimeout(() => AbortController.abort(controller), timeoutMs)

  Logger.debug(~module_="Resizer", ~message="CHECKING_HEALTH", ~data=Some({"url": requestUrl}), ())

  let networkProbe =
    Fetch.fetch(requestUrl, Fetch.requestInit(~method="GET", ~signal, ()))
    ->Promise.then(res => {
      let status = Fetch.status(res)
      if Fetch.ok(res) {
        Promise.resolve(true)
      } else {
        Logger.warn(
          ~module_="Resizer",
          ~message="HEALTH_CHECK_FAILED",
          ~data=Some({
            "status": status,
            "statusText": Fetch.statusText(res),
            "url": Constants.backendUrl ++ "/health",
          }),
          (),
        )
        Promise.resolve(false)
      }
    })
    ->Promise.catch(_ => Promise.resolve(false))

  let timeoutProbe = Promise.make((resolve, _reject) => {
    let _ = Window.setTimeout(() => resolve(false), timeoutMs + 200)
  })

  Promise.race([networkProbe, timeoutProbe])->Promise.then(result => {
    Window.clearTimeout(timeoutId)
    Promise.resolve(result)
  })
}
