/* src/systems/Resizer/ResizerUtils.res */

open ReBindings

let formatBytesToMB = (v: float): string => {
  Float.toFixed(v /. 1024.0 /. 1024.0, ~digits=0) ++ "MB"
}

let safeGetMemoryStats = (): option<(float, float, float)> => {
  %raw(`
    (function() {
      if (typeof window !== 'undefined' && window.performance && window.performance.memory) {
         var mem = window.performance.memory;
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
  let controller = AbortController.newAbortController()
  let _signal = AbortController.signal(controller)
  let timeoutId = Window.setTimeout(() => AbortController.abort(controller), 5000)
  let timestamp = Date.now()->Float.toString

  Logger.debug(
    ~module_="Resizer",
    ~message="CHECKING_HEALTH",
    ~data=Some({"url": Constants.backendUrl ++ "/health?t=" ++ timestamp}),
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
    if !Fetch.ok(res) {
      Logger.warn(
        ~module_="Resizer",
        ~message="HEALTH_CHECK_FAILED",
        ~data={
          "status": Fetch.status(res),
          "statusText": Fetch.statusText(res),
          "url": Constants.backendUrl ++ "/health",
        },
        (),
      )
    }
    Promise.resolve(Fetch.ok(res))
  })
  ->Promise.catch(err => {
    Window.clearTimeout(timeoutId)
    let (msg, stack) = Logger.getErrorDetails(err)
    Logger.warn(
      ~module_="Resizer",
      ~message="HEALTH_CHECK_ERROR",
      ~data={"error": msg, "stack": stack, "url": Constants.backendUrl ++ "/health"},
      (),
    )
    Promise.resolve(false)
  })
}
