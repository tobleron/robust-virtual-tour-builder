const DEV_HOSTS = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

const ROUTE_MAP = new Map([
  ['/home', 'home'],
  ['/home.html', 'home'],
  ['/pricing', 'pricing'],
  ['/pricing.html', 'pricing'],
  ['/signin', 'signin'],
  ['/signin.html', 'signin'],
  ['/signup', 'signup'],
  ['/signup.html', 'signup'],
  ['/forgot-password', 'forgot-password'],
  ['/forgot-password.html', 'forgot-password'],
  ['/reset-password', 'reset-password'],
  ['/reset-password.html', 'reset-password'],
  ['/dashboard', 'dashboard'],
  ['/dashboard.html', 'dashboard'],
  ['/account', 'account'],
  ['/account.html', 'account'],
]);

function normalizePath(pathname) {
  if (!pathname || pathname === '') return '/';
  const trimmed = pathname.trim().toLowerCase();
  if (trimmed === '/') return '/';
  return trimmed.replace(/\/+$/, '');
}

export function resolveAppSurface(pathname, hostname) {
  const path = normalizePath(pathname);
  const isDevHost = DEV_HOSTS.has((hostname || '').toLowerCase());

  if (path === '/index.html') return 'builder';
  if (path === '/') return isDevHost ? 'builder' : 'home';
  if (ROUTE_MAP.has(path)) return ROUTE_MAP.get(path);

  if (path.startsWith('/api/') || path === '/health' || path === '/metrics') {
    return 'builder';
  }

  return isDevHost ? 'builder' : 'home';
}

function nav(active) {
  const link = (href, label, key) =>
    `<a class="site-nav-link ${active === key ? 'is-active' : ''}" href="${href}">${label}</a>`;
  return `
    <header class="site-header">
      <div class="site-brand">
        <div class="site-brand-mark">ROBUST</div>
        <div class="site-brand-sub">Virtual Tour Builder</div>
      </div>
      <nav class="site-nav">
        ${link('/home', 'Home', 'home')}
        ${link('/pricing', 'Pricing', 'pricing')}
        ${link('/dashboard', 'Dashboard', 'dashboard')}
        ${link('/account', 'Account', 'account')}
      </nav>
      <div class="site-header-actions">
        <a class="site-btn site-btn-ghost" href="/signin">Sign In</a>
        <a class="site-btn site-btn-primary" href="/signup">Start Free</a>
      </div>
    </header>
  `;
}

function footer() {
  return `
    <footer class="site-footer">
      <div class="site-footer-left">
        <span class="site-footer-title">Robust Virtual Tour Builder</span>
        <span class="site-footer-copy">Production-ready 360 authoring and publishing workflow.</span>
      </div>
      <div class="site-footer-links">
        <a href="/pricing">Pricing</a>
        <a href="/signin">Sign In</a>
        <a href="/signup">Sign Up</a>
        <a href="/index.html">Open Builder</a>
      </div>
    </footer>
  `;
}

function homePage() {
  return `
    <section class="site-hero">
      <p class="site-kicker">Built For Real Estate Production Teams</p>
      <h1>Publish immersive tours quickly without sacrificing control.</h1>
      <p class="site-muted">Author on a robust stage builder, manage projects from one dashboard, and scale delivery with subscription-ready workflows.</p>
      <div class="site-hero-actions">
        <a class="site-btn site-btn-primary" href="/signup">Create Account</a>
        <a class="site-btn site-btn-ghost" href="/index.html">Open Builder</a>
      </div>
    </section>
    <section class="site-cards">
      <article class="site-card">
        <h3>Reliable Authoring</h3>
        <p>Scene graphing, hotspot sequencing, and simulation-ready traversal from one production canvas.</p>
      </article>
      <article class="site-card">
        <h3>Fast Publish Loop</h3>
        <p>Prepare tours with branded export profiles and predictable packaging behavior.</p>
      </article>
      <article class="site-card">
        <h3>Monetization Ready</h3>
        <p>Plan-based pricing and account scaffolding to convert traffic into paid builders.</p>
      </article>
    </section>
  `;
}

function pricingPage() {
  return `
    <section class="site-section-head">
      <h1>Simple plans built for growth</h1>
      <p class="site-muted">Start free, then upgrade when you need higher publishing limits and branded deliverables.</p>
    </section>
    <section class="site-pricing-grid">
      <article class="site-card">
        <h3>Free</h3>
        <p class="site-price">$0<span>/month</span></p>
        <ul><li>HD tour publishing</li><li>8 tours per month</li><li>Available for everyone</li></ul>
        <a class="site-btn site-btn-ghost" href="/signup">Get Started</a>
      </article>
      <article class="site-card site-card-accent">
        <h3>Pro</h3>
        <p class="site-price">$4.44<span>/month</span></p>
        <ul><li>2K publishing capability</li><li>24 tours per month</li><li>Best for active creators</li></ul>
        <a class="site-btn site-btn-primary" href="/signup">Choose Pro</a>
      </article>
      <article class="site-card">
        <h3>Enterprise</h3>
        <p class="site-price">Contact<span> sales</span></p>
        <ul><li>Custom pricing by agreement</li><li>Enterprise-scale deployment</li><li>Dedicated onboarding support</li></ul>
        <a class="site-btn site-btn-ghost" href="mailto:sales@robust-vtb.com">Contact Sales</a>
      </article>
    </section>
  `;
}

function authCard(title, subtitle, primaryLabel, secondaryHref, secondaryLabel, includeConfirm) {
  return `
    <section class="site-auth-wrap">
      <article class="site-auth-card">
        <h1>${title}</h1>
        <p class="site-muted">${subtitle}</p>
        <form class="site-form" onsubmit="return false;">
          <label>Email<input type="email" placeholder="you@company.com" /></label>
          <label>Password<input type="password" placeholder="********" /></label>
          ${includeConfirm ? '<label>Confirm Password<input type="password" placeholder="********" /></label>' : ''}
          <button class="site-btn site-btn-primary" type="submit">${primaryLabel}</button>
        </form>
        <a class="site-link-muted" href="${secondaryHref}">${secondaryLabel}</a>
      </article>
    </section>
  `;
}

function forgotPasswordPage() {
  return `
    <section class="site-auth-wrap">
      <article class="site-auth-card">
        <h1>Recover your password</h1>
        <p class="site-muted">Enter your account email and we will send a reset link.</p>
        <form class="site-form" onsubmit="return false;">
          <label>Email<input type="email" placeholder="you@company.com" /></label>
          <button class="site-btn site-btn-primary" type="submit">Send Reset Link</button>
        </form>
        <a class="site-link-muted" href="/signin">Back to sign in</a>
      </article>
    </section>
  `;
}

function resetPasswordPage() {
  return `
    <section class="site-auth-wrap">
      <article class="site-auth-card">
        <h1>Set a new password</h1>
        <p class="site-muted">Use a strong password before continuing to your dashboard.</p>
        <form class="site-form" onsubmit="return false;">
          <label>New Password<input type="password" placeholder="********" /></label>
          <label>Confirm Password<input type="password" placeholder="********" /></label>
          <button class="site-btn site-btn-primary" type="submit">Update Password</button>
        </form>
        <a class="site-link-muted" href="/signin">Return to sign in</a>
      </article>
    </section>
  `;
}

function dashboardPage() {
  const projects = [
    { name: 'Palm Residence Showcase', updated: '2h ago', scenes: 32, status: 'Published' },
    { name: 'Edge Compound Teaser', updated: '5h ago', scenes: 21, status: 'Draft' },
    { name: 'Marina Duplex Tour', updated: '1d ago', scenes: 44, status: 'Published' },
  ];
  const rows = projects
    .map(
      p => `
      <tr>
        <td>${p.name}</td>
        <td>${p.scenes}</td>
        <td>${p.updated}</td>
        <td><span class="site-chip">${p.status}</span></td>
        <td><a class="site-link" href="/index.html">Open Builder</a></td>
      </tr>
    `
    )
    .join('');

  return `
    <section class="site-section-head">
      <h1>Dashboard</h1>
      <p class="site-muted">Recent projects, publishing status, and quick actions.</p>
      <div class="site-hero-actions">
        <a class="site-btn site-btn-primary" href="/index.html">Create New Tour</a>
        <a class="site-btn site-btn-ghost" href="/pricing">Upgrade Plan</a>
      </div>
    </section>
    <section class="site-card">
      <table class="site-table">
        <thead><tr><th>Project</th><th>Scenes</th><th>Updated</th><th>Status</th><th>Action</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </section>
  `;
}

function accountPage() {
  return `
    <section class="site-section-head">
      <h1>Account Settings</h1>
      <p class="site-muted">Manage profile, security, and plan usage.</p>
    </section>
    <section class="site-cards">
      <article class="site-card">
        <h3>Profile</h3>
        <p>Name, company, and contact details.</p>
        <a class="site-link" href="#">Edit profile</a>
      </article>
      <article class="site-card">
        <h3>Security</h3>
        <p>Password, sessions, and authentication health.</p>
        <a class="site-link" href="/reset-password">Reset password</a>
      </article>
      <article class="site-card">
        <h3>Plan Usage</h3>
        <p>7 / 25 active tours • Pro plan</p>
        <a class="site-link" href="/pricing">Manage subscription</a>
      </article>
    </section>
  `;
}

function contentFor(page) {
  switch (page) {
    case 'home':
      return homePage();
    case 'pricing':
      return pricingPage();
    case 'signin':
      return authCard(
        'Sign in',
        'Access your dashboard and continue building tours.',
        'Sign In',
        '/forgot-password',
        'Forgot password?',
        false
      );
    case 'signup':
      return authCard(
        'Create account',
        'Start your free workspace and build your first tour.',
        'Create Account',
        '/signin',
        'Already have an account? Sign in',
        true
      );
    case 'forgot-password':
      return forgotPasswordPage();
    case 'reset-password':
      return resetPasswordPage();
    case 'dashboard':
      return dashboardPage();
    case 'account':
      return accountPage();
    default:
      return homePage();
  }
}

function titleFor(page) {
  const map = {
    home: 'Home',
    pricing: 'Pricing',
    signin: 'Sign In',
    signup: 'Sign Up',
    'forgot-password': 'Forgot Password',
    'reset-password': 'Reset Password',
    dashboard: 'Dashboard',
    account: 'Account Settings',
  };
  return map[page] || 'Home';
}

export function renderPageFramework(rootElement, page) {
  if (!rootElement) return;
  document.body.classList.add('site-framework-mode');
  document.title = `Robust Virtual Tour Builder | ${titleFor(page)}`;

  rootElement.innerHTML = `
    <div class="site-shell" id="main-content">
      ${nav(page)}
      <main class="site-main">
        ${contentFor(page)}
      </main>
      ${footer()}
    </div>
  `;
}
