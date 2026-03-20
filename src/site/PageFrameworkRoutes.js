// @efficiency-role: util-pure
export const DEV_HOSTS = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

const ROUTE_MAP = new Map([
  ['/builder', 'builder'],
  ['/builder.html', 'builder'],
  ['/home', 'home'],
  ['/home.html', 'home'],
  ['/pricing', 'pricing'],
  ['/pricing.html', 'pricing'],
  ['/signin', 'signin'],
  ['/signin.html', 'signin'],
  ['/setup', 'setup'],
  ['/setup.html', 'setup'],
  ['/signup', 'signup'],
  ['/signup.html', 'signup'],
  ['/local-reset', 'local-reset'],
  ['/local-reset.html', 'local-reset'],
  ['/forgot-password', 'forgot-password'],
  ['/forgot-password.html', 'forgot-password'],
  ['/check-email', 'check-email'],
  ['/check-email.html', 'check-email'],
  ['/verify-email', 'verify-email'],
  ['/verify-email.html', 'verify-email'],
  ['/reset-password', 'reset-password'],
  ['/reset-password.html', 'reset-password'],
  ['/dashboard', 'dashboard'],
  ['/dashboard.html', 'dashboard'],
  ['/account', 'account'],
  ['/account.html', 'account'],
]);

const PAGE_TITLES = {
  home: 'Home',
  pricing: 'Pricing',
  signin: 'Sign In',
  setup: 'Local Setup',
  signup: 'Sign Up',
  'local-reset': 'Local Reset',
  'forgot-password': 'Forgot Password',
  'check-email': 'Check Email',
  'verify-email': 'Verify Email',
  'reset-password': 'Reset Password',
  dashboard: 'Dashboard',
  account: 'Account Settings',
};

function normalizePath(pathname) {
  if (!pathname || pathname === '') return '/';
  const trimmed = pathname.trim().toLowerCase();
  if (trimmed === '/') return '/';
  return trimmed.replace(/\/+$/, '');
}

export function resolveAppSurface(pathname, hostname) {
  void hostname;
  const path = normalizePath(pathname);
  if (path === '/index.html' || path === '/') return 'home';
  if (ROUTE_MAP.has(path)) return ROUTE_MAP.get(path);

  if (path.startsWith('/api/') || path === '/health' || path === '/metrics') {
    return 'builder';
  }

  return 'home';
}

export function titleFor(page) {
  return PAGE_TITLES[page] || 'Home';
}

export function formatShortTimestamp(value) {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
}
