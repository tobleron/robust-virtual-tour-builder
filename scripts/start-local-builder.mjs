import {
  buildStableRuntime,
  ensureMainBranch,
  ensureRuntimeConfig,
  parseRuntimeArgs,
  platformName,
  printPlatformBootstrapHint,
  startStableRuntime,
} from './local-builder-runtime.mjs';

async function main() {
  const options = parseRuntimeArgs(process.argv.slice(2));
  console.log(`🧭 Stable builder runtime on ${platformName()}`);
  ensureMainBranch();
  const config = ensureRuntimeConfig(options);
  printPlatformBootstrapHint();
  buildStableRuntime({ resetTarget: options.resetTarget });
  await startStableRuntime(config);
}

main().catch(error => {
  console.error(`❌ ${error.message}`);
  process.exit(1);
});
