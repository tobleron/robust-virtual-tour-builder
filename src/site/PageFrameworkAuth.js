// @efficiency-role: ui-component
import { renderAuthActions } from './PageFrameworkShared.js';

export function getAuthHeaderValue() {
  const fromStorage = window.localStorage ? window.localStorage.getItem('auth_token') : null;
  if (fromStorage && fromStorage.trim() !== '') return `Bearer ${fromStorage}`;
  return null;
}

export async function authJson(path, payload, method = 'POST') {
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

export async function getAuthSession() {
  try {
    const me = await authJson('/api/auth/me', null, 'GET');
    if (me?.authenticated && me?.user) return me;
    return { authenticated: false, user: null };
  } catch (_error) {
    return { authenticated: false, user: null };
  }
}

export function updateAuthSurfaces(session) {
  document.querySelectorAll('[data-auth-surface]').forEach(node => {
    node.innerHTML = renderAuthActions(session, node.getAttribute('data-auth-surface') || 'site');
  });
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

export function redirectIfProtectedPageRequiresAuth(currentPage, session) {
  if (currentPage !== 'dashboard' && currentPage !== 'account') return true;
  if (session?.authenticated) return true;
  window.location.assign('/signin');
  return false;
}

function clearLocalAuthToken() {
  if (!window.localStorage) return;
  window.localStorage.removeItem('auth_token');
}

export async function signOutAndRedirect() {
  try {
    await authJson('/api/auth/signout', null);
  } catch (_error) {
    // Keep sign-out resilient; the local token is the critical path.
  } finally {
    clearLocalAuthToken();
    window.location.assign('/signin');
  }
}

export function bindAuthForms(page) {
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
