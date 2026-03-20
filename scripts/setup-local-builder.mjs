import {
  buildStableRuntime,
  ensureMainBranch,
  ensureRuntimeConfig,
  parseRuntimeArgs,
  platformName,
  startStableRuntime,
} from './local-builder-runtime.mjs';

async function main() {
  const options = parseRuntimeArgs(process.argv.slice(2));
  console.log(`🧱 Local builder setup on ${platformName()}`);
  ensureMainBranch();
  const config = ensureRuntimeConfig(options);
  buildStableRuntime({ resetTarget: options.resetTarget });
  await startStableRuntime(config);
}

main().catch(error => {
  console.error(`❌ ${error.message}`);
  process.exit(1);
});
