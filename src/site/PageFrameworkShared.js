// @efficiency-role: ui-component
import { contentFor } from './PageFrameworkContent.js';
import {
  DEV_HOSTS,
  formatShortTimestamp,
  resolveAppSurface,
  titleFor,
} from './PageFrameworkRoutes.js';

export function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, char => {
    switch (char) {
      case '&':
        return '&amp;';
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '"':
        return '&quot;';
      case "'":
        return '&#39;';
      default:
        return char;
    }
  });
}

function preferredUserLabel(user) {
  if (!user) return 'Account';
  return user.name?.trim() || user.username?.trim() || user.email?.trim() || 'Account';
}

function preferredUserMeta(user) {
  if (!user) return '';
  return user.username?.trim() || user.email?.trim() || '';
}

export function renderAuthActions(session, variant = 'site') {
  const isAuthenticated = Boolean(session?.authenticated && session?.user);
  if (!isAuthenticated) {
    return `
      <a class="site-btn site-btn-ghost" href="/signin">Sign In</a>
      <a class="site-btn site-btn-primary" href="/signup">Start Free</a>
    `;
  }

  const label = escapeHtml(preferredUserLabel(session.user));
  const meta = escapeHtml(preferredUserMeta(session.user));
  const accountLabel = variant === 'builder' ? 'Profile' : 'Account Settings';

  if (variant === 'builder') {
    return `
      <a class="site-user-chip site-user-chip-link" href="/account" title="Open account settings">
        <span class="site-user-avatar" aria-hidden="true">${label.slice(0, 1).toUpperCase()}</span>
        <span class="site-user-copy">
          <strong>${label}</strong>
          ${meta ? `<span>${meta}</span>` : ''}
        </span>
      </a>
      <button class="site-btn site-btn-primary" type="button" data-auth-signout="1">Sign Out</button>
    `;
  }

  return `
    <div class="site-user-chip">
      <span class="site-user-avatar" aria-hidden="true">${label.slice(0, 1).toUpperCase()}</span>
      <span class="site-user-copy">
        <strong>${label}</strong>
        ${meta ? `<span>${meta}</span>` : ''}
      </span>
    </div>
    <a class="site-btn site-btn-ghost" href="/account">${accountLabel}</a>
    <button class="site-btn site-btn-primary" type="button" data-auth-signout="1">Sign Out</button>
  `;
}

export function nav(active) {
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
      <div class="site-header-actions" data-auth-surface="site">
        ${renderAuthActions({ authenticated: false, user: null }, 'site')}
      </div>
    </header>
  `;
}

export function footer() {
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
export {
  contentFor,
  DEV_HOSTS,
  formatShortTimestamp,
  resolveAppSurface,
  titleFor,
};
