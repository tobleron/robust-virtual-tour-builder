const DEV_HOSTS = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

const ROUTE_MAP = new Map([
  ['/builder', 'builder'],
  ['/builder.html', 'builder'],
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

function normalizePath(pathname) {
  if (!pathname || pathname === '') return '/';
  const trimmed = pathname.trim().toLowerCase();
  if (trimmed === '/') return '/';
  return trimmed.replace(/\/+$/, '');
}

export function resolveAppSurface(pathname, hostname) {
  const path = normalizePath(pathname);
  if (path === '/index.html' || path === '/') return 'home';
  if (ROUTE_MAP.has(path)) return ROUTE_MAP.get(path);

  if (path.startsWith('/api/') || path === '/health' || path === '/metrics') {
    return 'builder';
  }

  return 'home';
}

function nav(active) {
  const link = (href, label, key) =>
    `<a class="site-nav-link ${active === key ? 'is-active' : ''}" href="${href}">${label}</a>`;
  return `
    <header class="site-header">
      <div class="site-brand">
        <div class="site-brand-lockup">
          <span class="site-brand-title">ROBUST</span>
          <svg class="site-brand-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" stroke="currentColor" stroke-width="2" />
            <path d="M9 22V12h6v10" stroke="currentColor" stroke-width="2" />
          </svg>
        </div>
        <div class="site-brand-sub">VIRTUAL TOUR BUILDER</div>
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
        <span class="site-footer-title">
          <span class="site-footer-brand-lockup">
            <span>ROBUST</span>
            <svg class="site-footer-brand-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" stroke="currentColor" stroke-width="2" />
              <path d="M9 22V12h6v10" stroke="currentColor" stroke-width="2" />
            </svg>
          </span>
        </span>
        <span class="site-footer-copy">Production-ready 360 authoring and publishing workflow.</span>
      </div>
      <div class="site-footer-links">
        <a href="/pricing">Pricing</a>
        <a href="/signin">Sign In</a>
        <a href="/signup">Sign Up</a>
        <a href="/builder">Open Builder</a>
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
        <a class="site-btn site-btn-ghost" href="/builder">Open Builder</a>
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

function authCard(title, subtitle, primaryLabel, secondaryHref, secondaryLabel, includeConfirm, includeUsername) {
  return `
    <section class="site-auth-wrap">
      <article class="site-auth-card">
        <h1>${title}</h1>
        <p class="site-muted">${subtitle}</p>
        <form class="site-form" onsubmit="return false;" data-auth-form="${includeConfirm ? 'signup' : 'signin'}">
          ${includeUsername ? '<label>Username<input type="text" name="username" placeholder="your-username" /></label>' : ''}
          <label>Email<input type="email" name="email" placeholder="you@company.com" /></label>
          <label>Password<input type="password" name="password" placeholder="********" /></label>
          ${includeConfirm ? '<label>Confirm Password<input type="password" name="confirmPassword" placeholder="********" /></label>' : ''}
          <p class="site-muted" data-auth-message=""></p>
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
        <form class="site-form" onsubmit="return false;" data-auth-form="forgot-password">
          <label>Email<input type="email" name="email" placeholder="you@company.com" /></label>
          <p class="site-muted" data-auth-message=""></p>
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
        <form class="site-form" onsubmit="return false;" data-auth-form="reset-password">
          <label>New Password<input type="password" name="newPassword" placeholder="********" /></label>
          <label>Confirm Password<input type="password" name="confirmNewPassword" placeholder="********" /></label>
          <p class="site-muted" data-auth-message=""></p>
          <button class="site-btn site-btn-primary" type="submit">Update Password</button>
        </form>
        <a class="site-link-muted" href="/signin">Return to sign in</a>
      </article>
    </section>
  `;
}

function verifyEmailPage() {
  return `
    <section class="site-auth-wrap">
      <article class="site-auth-card">
        <h1>Verify your email</h1>
        <p class="site-muted">Complete verification to activate your account.</p>
        <form class="site-form" onsubmit="return false;" data-auth-form="verify-email">
          <p class="site-muted" data-auth-message="">Press verify to continue.</p>
          <button class="site-btn site-btn-primary" type="submit">Verify Email</button>
        </form>
        <a class="site-link-muted" href="/signin">Go to sign in</a>
      </article>
    </section>
  `;
}

function checkEmailPage() {
  return `
    <section class="site-auth-wrap">
      <article class="site-auth-card">
        <h1>Check your email</h1>
        <p class="site-muted">We sent a verification link to your inbox. Verify your account, then continue to sign in.</p>
        <form class="site-form" onsubmit="return false;" data-auth-form="check-email">
          <label>Email<input type="email" name="email" placeholder="you@company.com" /></label>
          <p class="site-muted" data-auth-message="">Didn’t receive it? Resend a new verification email.</p>
          <button class="site-btn site-btn-primary" type="submit">Resend Verification Email</button>
        </form>
        <div class="site-hero-actions">
          <a class="site-btn site-btn-ghost" href="/signup">Change Email</a>
          <a class="site-btn site-btn-ghost" href="/signin">I Already Verified</a>
        </div>
      </article>
    </section>
  `;
}

function dashboardPage() {
  return `
    <section class="site-section-head">
      <h1>Dashboard</h1>
      <p class="site-muted">Recent projects, publishing status, and quick actions.</p>
      <div class="site-hero-actions">
        <a class="site-btn site-btn-primary" href="/builder">Create New Tour</a>
        <a class="site-btn site-btn-ghost" href="/pricing">Upgrade Plan</a>
      </div>
    </section>
    <section class="site-card">
      <table class="site-table">
        <thead><tr><th>Project</th><th>Scenes</th><th>Updated</th><th>Status</th><th>Action</th></tr></thead>
        <tbody id="site-dashboard-projects">
          <tr><td colspan="5">Loading saved tours...</td></tr>
        </tbody>
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
        false,
        false
      );
    case 'signup':
      return authCard(
        'Create account',
        'Start your free workspace and build your first tour.',
        'Create Account',
        '/signin',
        'Already have an account? Sign in',
        true,
        true
      );
    case 'forgot-password':
      return forgotPasswordPage();
    case 'check-email':
      return checkEmailPage();
    case 'verify-email':
      return verifyEmailPage();
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
    'check-email': 'Check Email',
    'verify-email': 'Verify Email',
    'reset-password': 'Reset Password',
    dashboard: 'Dashboard',
    account: 'Account Settings',
  };
  return map[page] || 'Home';
}

function getAuthHeaderValue() {
  const fromStorage = window.localStorage ? window.localStorage.getItem('auth_token') : null;
  if (fromStorage && fromStorage.trim() !== '') return `Bearer ${fromStorage}`;
  if (DEV_HOSTS.has((window.location.hostname || '').toLowerCase())) return 'Bearer dev-token';
  return null;
}

async function authJson(path, payload, method = 'POST') {
  const auth = getAuthHeaderValue();
  const headers = { 'Content-Type': 'application/json' };
  if (auth) headers.Authorization = auth;
  const response = await fetch(path, {
    method,
    headers,
    body: payload ? JSON.stringify(payload) : undefined,
    credentials: 'include',
  });
  const json = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = json?.details || json?.error || `HTTP_${response.status}`;
    throw new Error(message);
  }
  return json;
}

function setAuthMessage(form, message, isError = false) {
  const node = form.querySelector('[data-auth-message]');
  if (!node) return;
  node.textContent = message;
  node.style.color = isError ? '#ffb4b4' : '#c7d4ed';
}

function ensureStepUpFields(form) {
  let wrap = form.querySelector('[data-step-up-wrap]');
  if (wrap) return wrap;
  wrap = document.createElement('div');
  wrap.setAttribute('data-step-up-wrap', '1');
  wrap.innerHTML = `
    <label>Verification Code<input type="text" name="otpCode" placeholder="6-digit code" /></label>
    <div style="display:flex; gap:10px;">
      <button class="site-btn site-btn-ghost" type="button" data-step-up-resend="1">Resend Code</button>
    </div>
  `;
  const submit = form.querySelector('button[type="submit"]');
  form.insertBefore(wrap, submit);
  return wrap;
}

function getTokenFromQuery() {
  const params = new URLSearchParams(window.location.search || '');
  const raw = params.get('token');
  return raw && raw.trim() !== '' ? raw.trim() : null;
}

function getEmailFromQuery() {
  const params = new URLSearchParams(window.location.search || '');
  const raw = params.get('email');
  return raw && raw.trim() !== '' ? raw.trim() : '';
}

async function ensureAuthenticatedOrRedirect(currentPage) {
  if (currentPage !== 'dashboard' && currentPage !== 'account') return true;
  try {
    const me = await authJson('/api/auth/me', null, 'GET');
    if (!me?.authenticated) {
      window.location.assign('/signin');
      return false;
    }
    return true;
  } catch (_error) {
    window.location.assign('/signin');
    return false;
  }
}

function bindAuthForms(page) {
  if (page === 'check-email') {
    const emailInput = document.querySelector('input[name="email"]');
    if (emailInput) {
      const initial = getEmailFromQuery();
      if (initial) emailInput.value = initial;
    }
  }

  const forms = Array.from(document.querySelectorAll('form[data-auth-form]'));
  forms.forEach(form => {
    form.addEventListener('submit', async event => {
      event.preventDefault();
      const mode = form.getAttribute('data-auth-form');
      const email = form.querySelector('input[name="email"]')?.value?.trim() || '';
      const username = form.querySelector('input[name="username"]')?.value?.trim() || '';
      const password = form.querySelector('input[name="password"]')?.value || '';
      const confirmPassword = form.querySelector('input[name="confirmPassword"]')?.value || '';
      const newPassword = form.querySelector('input[name="newPassword"]')?.value || '';
      const confirmNewPassword = form.querySelector('input[name="confirmNewPassword"]')?.value || '';
      const tokenFromUrl = getTokenFromQuery();

      try {
        if (mode === 'signup') {
          if (password !== confirmPassword) throw new Error('Passwords do not match.');
          await authJson('/api/auth/signup', {
            email,
            username,
            password,
            displayName: username,
          });
          window.location.assign(`/check-email?email=${encodeURIComponent(email)}`);
          return;
        }

        if (mode === 'signin') {
          const challengeId = form.getAttribute('data-challenge-id');
          if (challengeId) {
            const otpCode = form.querySelector('input[name="otpCode"]')?.value?.trim() || '';
            if (!otpCode) throw new Error('Enter verification code.');
            const verified = await authJson('/api/auth/step-up/verify', {
              challengeId,
              otpCode,
            });
            if (window.localStorage && verified?.token) {
              window.localStorage.setItem('auth_token', verified.token);
            }
            form.removeAttribute('data-challenge-id');
            window.location.assign('/dashboard');
            return;
          }

          const result = await authJson('/api/auth/signin', { email, password });
          if (result?.challengeRequired) {
            form.setAttribute('data-challenge-id', result.challengeId);
            ensureStepUpFields(form);
            const resend = form.querySelector('[data-step-up-resend="1"]');
            if (resend && !resend.getAttribute('data-bound')) {
              resend.setAttribute('data-bound', '1');
              resend.addEventListener('click', async () => {
                try {
                  const cid = form.getAttribute('data-challenge-id');
                  if (!cid) return;
                  await authJson('/api/auth/step-up/resend', { challengeId: cid });
                  setAuthMessage(form, 'New code sent to your email.', false);
                } catch (error) {
                  setAuthMessage(form, error?.message || 'Resend failed.', true);
                }
              });
            }
            setAuthMessage(form, result.message || 'We sent a verification code to your email.', false);
            return;
          }
          if (window.localStorage && result?.token) {
            window.localStorage.setItem('auth_token', result.token);
          }
          window.location.assign('/dashboard');
          return;
        }

        if (mode === 'check-email') {
          if (!email) throw new Error('Enter your account email.');
          await authJson('/api/auth/resend-verification', { email });
          setAuthMessage(form, 'If this account exists and is not verified, a new email was sent.', false);
          return;
        }

        if (mode === 'forgot-password') {
          await authJson('/api/auth/forgot-password', { email });
          setAuthMessage(form, 'If your email exists, reset instructions were sent.', false);
          return;
        }

        if (mode === 'verify-email') {
          if (!tokenFromUrl) throw new Error('Missing verification token in URL.');
          await authJson('/api/auth/verify-email', { token: tokenFromUrl });
          setAuthMessage(form, 'Email verified. Redirecting to sign in...', false);
          window.setTimeout(() => window.location.assign('/signin'), 1200);
          return;
        }

        if (mode === 'reset-password') {
          if (!tokenFromUrl) throw new Error('Missing reset token in URL.');
          if (newPassword !== confirmNewPassword) throw new Error('Passwords do not match.');
          await authJson('/api/auth/reset-password', { token: tokenFromUrl, newPassword });
          setAuthMessage(form, 'Password updated. Redirecting to sign in...', false);
          window.setTimeout(() => window.location.assign('/signin'), 1200);
          return;
        }
      } catch (error) {
        const msg = error?.message || 'Request failed.';
        if (mode === 'signin' && msg.toLowerCase().includes('not verified')) {
          window.location.assign(`/check-email?email=${encodeURIComponent(email)}`);
          return;
        }
        setAuthMessage(form, msg, true);
      }
    });
  });
}

async function loadDashboardProjects() {
  const tbody = document.getElementById('site-dashboard-projects');
  if (!tbody) return;

  try {
    const auth = getAuthHeaderValue();
    const headers = {};
    if (auth) headers.Authorization = auth;
    const response = await fetch('/api/project/dashboard/projects', {
      method: 'GET',
      headers,
      credentials: 'include',
    });

    if (!response.ok) {
      throw new Error(`HTTP_${response.status}`);
    }

    const projects = await response.json();
    if (!Array.isArray(projects) || projects.length === 0) {
      tbody.innerHTML = `<tr><td colspan="5">No saved tours yet.</td></tr>`;
      return;
    }

    tbody.innerHTML = projects
      .map(p => {
        const sessionId = encodeURIComponent(p.sessionId || '');
        const projectName = p.tourName || 'Untitled Tour';
        const scenes = Number.isFinite(p.sceneCount) ? p.sceneCount : 0;
        const updated = p.updatedAt || '-';
        return `
          <tr>
            <td>${projectName}</td>
            <td>${scenes}</td>
            <td>${updated}</td>
            <td><span class="site-chip">Saved</span></td>
            <td><a class="site-link" href="/builder?projectId=${sessionId}">Open Builder</a></td>
          </tr>
        `;
      })
      .join('');
  } catch (_error) {
    tbody.innerHTML = `<tr><td colspan="5">Failed to load dashboard projects.</td></tr>`;
  }
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

  ensureAuthenticatedOrRedirect(page).then(isAllowed => {
    if (!isAllowed) return;
    if (page === 'dashboard') loadDashboardProjects();
    bindAuthForms(page);
  });
}
