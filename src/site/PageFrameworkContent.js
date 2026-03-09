// @efficiency-role: ui-component
import { DEV_HOSTS } from './PageFrameworkRoutes.js';

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
  const showDevLogin = !includeConfirm && DEV_HOSTS.has((window.location.hostname || '').toLowerCase());
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
          ${showDevLogin ? '<button class="site-btn site-btn-ghost" type="button" data-auth-dev-login="1">Use Dev Account</button><p class="site-muted">Local development only. Creates or reuses a verified local user and signs in immediately.</p>' : ''}
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

export function contentFor(page) {
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
