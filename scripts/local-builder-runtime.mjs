import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const ROOT_DIR = path.resolve(path.dirname(__filename), '..');
const BACKEND_DIR = path.join(ROOT_DIR, 'backend');
const CONFIG_DIR = path.join(ROOT_DIR, 'config');
const RUNTIME_CONFIG_PATH = path.join(CONFIG_DIR, 'builder.runtime.toml');
const RUNTIME_CONFIG_EXAMPLE_PATH = path.join(CONFIG_DIR, 'builder.runtime.toml.example');
const LOCAL_ENV_PATH = path.join(BACKEND_DIR, '.env.local-builder');

function fail(message) {
  throw new Error(message);
}

export function runCommand(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: ROOT_DIR,
    stdio: 'inherit',
    env: process.env,
    ...options,
  });
  if (result.status !== 0) {
    fail(`${command} ${args.join(' ')} failed with exit code ${result.status ?? 'unknown'}`);
  }
}

function runCapture(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: ROOT_DIR,
    stdio: ['ignore', 'pipe', 'pipe'],
    encoding: 'utf8',
    env: process.env,
    ...options,
  });
  if (result.status !== 0) {
    const stderr = (result.stderr || '').trim();
    fail(stderr || `${command} ${args.join(' ')} failed`);
  }
  return (result.stdout || '').trim();
}

function parseToml(text) {
  const config = {};
  let section = null;

  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    if (line.startsWith('[') && line.endsWith(']')) {
      section = line.slice(1, -1).trim();
      if (!section) fail('Invalid TOML section header.');
      config[section] ||= {};
      continue;
    }

    const separator = line.indexOf('=');
    if (separator === -1) continue;
    const key = line.slice(0, separator).trim();
    const rawValue = line.slice(separator + 1).trim();
    let value = rawValue;
    if (/^".*"$/.test(rawValue)) {
      value = rawValue.slice(1, -1);
    } else if (/^-?\d+$/.test(rawValue)) {
      value = Number.parseInt(rawValue, 10);
    }

    if (section) {
      config[section] ||= {};
      config[section][key] = value;
    } else {
      config[key] = value;
    }
  }

  return config;
}

function serializeToml(config) {
  return [
    '[app]',
    `surface = "${config.app.surface}"`,
    `profile = "${config.app.profile}"`,
    '',
    '[server]',
    `host = "${config.server.host}"`,
    `port = ${config.server.port}`,
    '',
    '[public]',
    `base_url = "${config.public.base_url}"`,
    '',
  ].join('\n');
}

function normalizeRuntimeConfig(parsed) {
  const profile = parsed?.app?.profile === 'vps' ? 'vps' : 'local';
  const host = typeof parsed?.server?.host === 'string' && parsed.server.host.trim() !== ''
    ? parsed.server.host.trim()
    : profile === 'vps'
      ? '0.0.0.0'
      : '127.0.0.1';
  const port = Number.isInteger(parsed?.server?.port) && parsed.server.port > 0
    ? parsed.server.port
    : 8080;
  const baseUrl = typeof parsed?.public?.base_url === 'string' && parsed.public.base_url.trim() !== ''
    ? parsed.public.base_url.trim()
    : `http://${profile === 'vps' ? '127.0.0.1' : host}:${port}`;

  return {
    app: {
      surface: 'builder',
      profile,
    },
    server: {
      host,
      port,
    },
    public: {
      base_url: baseUrl,
    },
  };
}

function applyRuntimeOverrides(config, overrides = {}) {
  const next = structuredClone(config);
  if (overrides.profile === 'local' || overrides.profile === 'vps') next.app.profile = overrides.profile;
  if (typeof overrides.host === 'string' && overrides.host.trim() !== '') next.server.host = overrides.host.trim();
  if (Number.isInteger(overrides.port) && overrides.port > 0) next.server.port = overrides.port;
  if (typeof overrides.baseUrl === 'string' && overrides.baseUrl.trim() !== '') next.public.base_url = overrides.baseUrl.trim();
  return normalizeRuntimeConfig(next);
}

export function ensureRuntimeConfig(overrides = {}) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  if (!fs.existsSync(RUNTIME_CONFIG_PATH)) {
    let initial = normalizeRuntimeConfig(parseToml(fs.readFileSync(RUNTIME_CONFIG_EXAMPLE_PATH, 'utf8')));
    initial = applyRuntimeOverrides(initial, overrides);
    fs.writeFileSync(RUNTIME_CONFIG_PATH, serializeToml(initial), 'utf8');
  }

  const parsed = parseToml(fs.readFileSync(RUNTIME_CONFIG_PATH, 'utf8'));
  const config = applyRuntimeOverrides(normalizeRuntimeConfig(parsed), overrides);
  fs.writeFileSync(RUNTIME_CONFIG_PATH, serializeToml(config), 'utf8');
  return config;
}

function parseEnvFile(text) {
  const values = {};
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const index = line.indexOf('=');
    if (index === -1) continue;
    values[line.slice(0, index).trim()] = line.slice(index + 1).trim();
  }
  return values;
}

function makeSecret(size = 48) {
  return crypto.randomBytes(size).toString('base64url');
}

export function ensureLocalEnv() {
  if (!fs.existsSync(LOCAL_ENV_PATH)) {
    const initial = [
      'NODE_ENV=production',
      `JWT_SECRET=${makeSecret(32)}`,
      `SESSION_KEY=${makeSecret(64)}`,
      'BYPASS_AUTH=false',
      'ALLOW_DEV_AUTH_BOOTSTRAP=false',
      'DATABASE_URL=sqlite://data/database.db',
      'STORAGE_PATH=./storage',
      'LOG_LEVEL=info',
      'LOG_DIR=./logs',
      'TEMP_DIR=./temp',
      'SESSIONS_DIR=./sessions',
      'ALLOW_DISK_CHECK_BYPASS=false',
      '',
    ].join('\n');
    fs.writeFileSync(LOCAL_ENV_PATH, initial, 'utf8');
  }

  return parseEnvFile(fs.readFileSync(LOCAL_ENV_PATH, 'utf8'));
}

function deriveCorsOrigins(config) {
  const origins = new Set([config.public.base_url]);
  if (config.app.profile === 'local') {
    origins.add(`http://127.0.0.1:${config.server.port}`);
    origins.add(`http://localhost:${config.server.port}`);
  }
  return Array.from(origins).join(',');
}

function sha256Hex(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function createBootstrapContext(config) {
  if (config.app.profile !== 'vps') {
    return {
      env: {
        LOCAL_SETUP_BOOTSTRAP_MODE: 'local',
        LOCAL_SETUP_BOOTSTRAP_TOKEN_HASH: '',
        LOCAL_SETUP_BOOTSTRAP_EXPIRES_AT: '',
      },
      setupUrl: null,
    };
  }

  const token = crypto.randomBytes(24).toString('base64url');
  const expiresAt = Math.floor(Date.now() / 1000) + 60 * 60;
  const setupUrl = new URL('/setup', config.public.base_url);
  setupUrl.searchParams.set('token', token);

  return {
    env: {
      LOCAL_SETUP_BOOTSTRAP_MODE: 'token',
      LOCAL_SETUP_BOOTSTRAP_TOKEN_HASH: sha256Hex(token),
      LOCAL_SETUP_BOOTSTRAP_EXPIRES_AT: String(expiresAt),
    },
    setupUrl: setupUrl.toString(),
  };
}

export function buildBackendEnv(config) {
  const baseEnv = ensureLocalEnv();
  const bootstrap = createBootstrapContext(config);
  return {
    ...process.env,
    ...baseEnv,
    APP_SURFACE: 'builder',
    NODE_ENV: 'production',
    BYPASS_AUTH: 'false',
    ALLOW_DEV_AUTH_BOOTSTRAP: 'false',
    BACKEND_HOST: config.server.host,
    PORT: String(config.server.port),
    APP_BASE_URL: config.public.base_url,
    CORS_ALLOWED_ORIGINS: deriveCorsOrigins(config),
    ...bootstrap.env,
    __setupUrl: bootstrap.setupUrl ?? '',
  };
}

export function ensureMainBranch() {
  const currentBranch = runCapture('git', ['branch', '--show-current']);
  if (currentBranch === 'main') return;

  const dirty = runCapture('git', ['status', '--porcelain']);
  const hasLocalMain = spawnSync('git', ['show-ref', '--verify', '--quiet', 'refs/heads/main'], {
    cwd: ROOT_DIR,
    env: process.env,
  }).status === 0;
  const hasOriginMain = spawnSync('git', ['show-ref', '--verify', '--quiet', 'refs/remotes/origin/main'], {
    cwd: ROOT_DIR,
    env: process.env,
  }).status === 0;

  if (currentBranch === '') {
    if (dirty !== '') {
      fail(
        'Stable local start requires a clean checkout of main. Repository is in detached HEAD state with uncommitted changes.'
      );
    }

    if (hasLocalMain) {
      console.log('🔀 Detached HEAD detected. Switching to local main branch.');
      runCommand('git', ['checkout', 'main']);
      return;
    }

    if (hasOriginMain) {
      console.log('🔀 Detached HEAD detected. Creating local main branch from origin/main.');
      runCommand('git', ['checkout', '-B', 'main', '--track', 'origin/main']);
      return;
    }

    fail('Stable local start requires a main branch, but this checkout has no local or remote main ref.');
  }

  if (dirty !== '') {
    fail(
      `Stable local start requires main. Current branch is "${currentBranch}" with uncommitted changes. Commit or stash first, then rerun.`
    );
  }

  console.log(`🔀 Switching branch: ${currentBranch} -> main`);
  runCommand('git', ['checkout', 'main']);
}

export function ensureNodeModules() {
  if (!fs.existsSync(path.join(ROOT_DIR, 'node_modules'))) {
    console.log('📦 Installing frontend dependencies...');
    runCommand('npm', ['install']);
  }
}

export function buildStableRuntime({ resetTarget = false } = {}) {
  ensureNodeModules();
  if (resetTarget && fs.existsSync(path.join(BACKEND_DIR, 'target'))) {
    fs.rmSync(path.join(BACKEND_DIR, 'target'), { recursive: true, force: true });
  }

  console.log('📦 Building frontend bundle...');
  runCommand('npm', ['run', 'build']);

  console.log('🛠️ Building backend release binary...');
  runCommand('cargo', ['build', '--release'], {
    cwd: BACKEND_DIR,
    env: { ...process.env, CARGO_INCREMENTAL: '1' },
  });
}

function backendBinaryPath() {
  const name = process.platform === 'win32' ? 'backend.exe' : 'backend';
  return path.join(BACKEND_DIR, 'target', 'release', name);
}

function healthHost(config) {
  return config.server.host === '0.0.0.0' ? '127.0.0.1' : config.server.host;
}

function withPort(baseUrl, port) {
  const next = new URL(baseUrl);
  next.port = String(port);
  return next.toString();
}

async function isPortAvailable(host, port) {
  return new Promise(resolve => {
    const server = net.createServer();

    server.once('error', error => {
      if (error && (error.code === 'EADDRINUSE' || error.code === 'EACCES')) {
        resolve(false);
        return;
      }
      resolve(false);
    });

    server.once('listening', () => {
      server.close(() => resolve(true));
    });

    server.listen(port, host);
  });
}

async function ensureStartupPort(config) {
  const portIsFree = await isPortAvailable(config.server.host, config.server.port);
  if (portIsFree) return config;

  if (config.app.profile !== 'local') {
    fail(
      `Port ${config.server.port} is already in use on ${config.server.host}. Update config/builder.runtime.toml or stop the conflicting service, then rerun.`
    );
  }

  for (let candidate = config.server.port + 1; candidate <= config.server.port + 20; candidate += 1) {
    const candidateIsFree = await isPortAvailable(config.server.host, candidate);
    if (!candidateIsFree) continue;

    const nextConfig = {
      ...config,
      server: {
        ...config.server,
        port: candidate,
      },
      public: {
        ...config.public,
        base_url: withPort(config.public.base_url, candidate),
      },
    };

    fs.writeFileSync(RUNTIME_CONFIG_PATH, serializeToml(nextConfig), 'utf8');
    console.log(`⚠️ Port ${config.server.port} is busy. Switching local builder to ${nextConfig.public.base_url}.`);
    return nextConfig;
  }

  fail(
    `Port ${config.server.port} is busy and no free local fallback port was found in the next 20 ports.`
  );
}

async function waitForHealth(config, child) {
  const host = healthHost(config);
  const deadline = Date.now() + 90_000;

  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      fail('Backend exited before becoming healthy.');
    }

    const ok = await new Promise(resolve => {
      const req = http.get(
        {
          hostname: host,
          port: config.server.port,
          path: '/health',
          timeout: 2_000,
        },
        response => {
          response.resume();
          resolve(response.statusCode && response.statusCode < 500);
        }
      );
      req.on('error', () => resolve(false));
      req.on('timeout', () => {
        req.destroy();
        resolve(false);
      });
    });

    if (ok) return;
    await new Promise(resolve => setTimeout(resolve, 1_000));
  }

  fail('Backend did not become healthy in time.');
}

export async function startStableRuntime(config) {
  const resolvedConfig = await ensureStartupPort(config);
  const env = buildBackendEnv(resolvedConfig);
  const setupUrl = env.__setupUrl || '';
  delete env.__setupUrl;

  console.log(`🚀 Starting builder on ${resolvedConfig.public.base_url}`);
  if (setupUrl) {
    console.log(`🔐 First-time remote setup URL: ${setupUrl}`);
  }

  const child = spawn(backendBinaryPath(), [], {
    cwd: BACKEND_DIR,
    env,
    stdio: 'inherit',
  });

  const shutdown = signal => {
    if (!child.killed) {
      child.kill(signal);
    }
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));

  await waitForHealth(resolvedConfig, child);
  console.log(`✅ Builder ready at ${resolvedConfig.public.base_url}`);

  await new Promise((resolve, reject) => {
    child.on('exit', code => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Backend exited with code ${code}`));
      }
    });
    child.on('error', reject);
  });
}

export function parseRuntimeArgs(argv) {
  const options = {
    profile: undefined,
    host: undefined,
    port: undefined,
    baseUrl: undefined,
    resetTarget: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--profile') options.profile = argv[index + 1];
    if (arg === '--host') options.host = argv[index + 1];
    if (arg === '--port') options.port = Number.parseInt(argv[index + 1], 10);
    if (arg === '--base-url') options.baseUrl = argv[index + 1];
    if (arg === '--reset-target') options.resetTarget = true;
  }

  return options;
}

export function printPlatformBootstrapHint() {
  const platform = process.platform;
  if (platform === 'darwin') {
    console.log('Use ./scripts/setup-local-builder.sh for first-time setup on macOS.');
    return;
  }
  if (platform === 'win32') {
    console.log('Use PowerShell ./scripts/setup-local-builder.ps1 for first-time setup on Windows.');
    return;
  }
  console.log('Use ./scripts/setup-local-builder.sh for first-time setup on Linux.');
}

export function platformName() {
  if (process.platform === 'darwin') return 'macOS';
  if (process.platform === 'win32') return 'Windows';
  if (process.platform === 'linux') return 'Linux';
  return os.platform();
}
