/* src/systems/ResizerUtils.res */

open ReBindings

/**
 * Generate a SHA-256 checksum for a file (Client-side).
 * Used for "fingerprinting" images to detect duplicates before upload.
 */
let getChecksum = (file: File.t): Promise.t<string> => {
  let internalGetChecksum: File.t => Promise.t<string> = %raw(`
     async function(file) {
        const SMALL_FILE_THRESHOLD = 10 * 1024 * 1024;
        const SAMPLE_SIZE = 1024 * 1024;
        let hashBuffer;
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
            sampleBuffers.forEach(buf => {
                combined.set(new Uint8Array(buf), offset);
                offset += buf.byteLength;
            });
            hashBuffer = await crypto.subtle.digest('SHA-256', combined);
        }
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        return hash + "_" + file.size;
     }
   `)

  internalGetChecksum(file)
}

/**
 * Checks if the backend is reachable
 */
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
        ~message="Backend Health Check Failed: " ++ Fetch.statusText(res),
        (),
      )
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
