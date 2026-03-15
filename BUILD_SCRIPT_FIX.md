# Portal Build Script Fix

## Problem Identified

The `/root/scripts/robust-vtb-full-build.sh` script on the VPS was **deleting `backend/target`** on every run:

```bash
rm -rf dist-portal backend/target  # <-- THIS WAS THE PROBLEM
```

This caused **FULL REBUILDS every time** instead of incremental compilation.

## Solution Implemented

### 1. Created New Incremental Build Script

**File**: `/root/scripts/robust-vtb-portal-build.sh`

```bash
#!/bin/bash
set -euo pipefail
cd /opt/robust-vtb/current

# Only clean dist-portal, NOT backend/target (for incremental builds)
rm -rf dist-portal  # <-- NO backend/target deletion!

npm run build:portal
cd backend
APP_DIST_ROOT="/opt/robust-vtb/current/dist-portal" \
APP_SURFACE=portal \
cargo build --release --bin portal --no-default-features --features portal-runtime

install -m 755 target/release/portal /opt/robust-vtb/bin/portal
cd /opt/robust-vtb/current

# Clean npm cache but NOT backend/target
npm cache clean --force || true
apt-get clean || true
```

### 2. Updated Deploy Script

**File**: `scripts/deploy-portal-vps.sh`

Changed the default build script from:
```bash
REMOTE_BUILD_SCRIPT="${PORTAL_VPS_BUILD_SCRIPT:-/root/scripts/robust-vtb-full-build.sh}"
```

To:
```bash
REMOTE_BUILD_SCRIPT="${PORTAL_VPS_BUILD_SCRIPT:-/root/scripts/robust-vtb-portal-build.sh}"
```

## Expected Build Times

| Scenario | Before Fix | After Fix |
|----------|-----------|-----------|
| No code changes | 3-5 minutes | 5-15 seconds |
| Changed 1-2 Rust files | 3-5 minutes | 10-30 seconds |
| Changed dependencies | 3-5 minutes | 1-3 minutes |
| First deployment | 3-5 minutes | 3-5 minutes |

## How to Use

### Normal Deployment (Incremental)
```bash
./scripts/update-portal.sh
```

### Force Full Rebuild (if needed)
```bash
REMOTE_RESET_TARGET=1 ./scripts/update-portal.sh
```

## Verification

After running `update-portal.sh`, check the build output:

```bash
ssh root@portal-vps "cat /tmp/cargo-build.log | grep -E 'Fresh|Compiling' | tail -20"
```

**Good output** (incremental):
```
Fresh tokio v1.49.0
Fresh serde v1.0.228
Compiling backend v0.1.0 (/opt/robust-vtb/current/backend)  # Only your code!
```

**Bad output** (full rebuild - should NOT happen):
```
Compiling tokio v1.49.0
Compiling serde v1.0.228
Compiling actix-web v4.12.1
... (hundreds of dependencies)
```

## What Was NOT the Problem

1. ✅ rsync was correctly excluding `backend/target`
2. ✅ Cargo incremental compilation was enabled
3. ✅ File timestamps were being preserved
4. ✅ The deploy script logic was correct

**The ONLY issue was the remote build script deleting `backend/target`.**

## Files Changed

1. `/root/scripts/robust-vtb-portal-build.sh` (NEW on VPS) - Incremental build script
2. `scripts/deploy-portal-vps.sh` - Updated to use new build script by default
3. `scripts/update-portal.sh` - No changes needed (uses deploy-portal-vps.sh)

## Future Considerations

If you ever need to do a FULL rebuild (e.g., after Rust version upgrade):

```bash
REMOTE_RESET_TARGET=1 ./scripts/update-portal.sh
```

This will:
1. Delete `backend/target` on the server
2. Force a complete recompilation
3. Create a fresh build cache for future incremental builds
