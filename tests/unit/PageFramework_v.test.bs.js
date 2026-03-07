import { describe, expect, test, beforeEach, afterEach, vi } from 'vitest';
import { renderPageFramework, resolveAppSurface } from '../../src/site/PageFramework.js';

describe('PageFramework', () => {
  test('resolveAppSurface maps routes correctly in dev/prod', () => {
    expect(resolveAppSurface('/', 'localhost')).toBe('home');
    expect(resolveAppSurface('/', 'example.com')).toBe('home');
    expect(resolveAppSurface('/index.html', 'example.com')).toBe('home');
    expect(resolveAppSurface('/check-email', 'example.com')).toBe('check-email');
    expect(resolveAppSurface('/account', 'example.com')).toBe('account');
    expect(resolveAppSurface('/unknown', 'localhost')).toBe('home');
    expect(resolveAppSurface('/unknown', 'example.com')).toBe('home');
  });

  describe('renderPageFramework', () => {
    let root;

    beforeEach(() => {
      window.history.replaceState({}, '', '/');
      root = document.createElement('div');
      document.body.appendChild(root);
      vi.stubGlobal('fetch', vi.fn());
    });

    afterEach(() => {
      vi.unstubAllGlobals();
      root.remove();
      document.body.classList.remove('site-framework-mode');
    });

    test('renders pricing page with current package model', () => {
      renderPageFramework(root, 'pricing');

      expect(root.textContent).toContain('Free');
      expect(root.textContent).toContain('$0');
      expect(root.textContent).toContain('8 tours per month');
      expect(root.textContent).toContain('Pro');
      expect(root.textContent).toContain('$4.44');
      expect(root.textContent).toContain('24 tours per month');
      expect(root.textContent).toContain('Enterprise');
      expect(root.textContent).toContain('Contact sales');
    });

    test('renders builder-consistent brand lockup in header', () => {
      renderPageFramework(root, 'home');

      const header = root.querySelector('.site-header');
      expect(header).not.toBeNull();
      expect(header.textContent).toContain('ROBUST');
      expect(header.textContent).toContain('VIRTUAL TOUR BUILDER');
      expect(header.querySelector('.site-brand-icon')).not.toBeNull();
    });

    test('renders check-email page and prefills email from query', async () => {
      window.history.replaceState({}, '', '/check-email?email=user%40example.com');
      renderPageFramework(root, 'check-email');
      await Promise.resolve();

      const form = root.querySelector('form[data-auth-form="check-email"]');
      expect(form).not.toBeNull();
      expect(root.textContent).toContain('Check your email');
      const emailInput = root.querySelector('input[name="email"]');
      expect(emailInput.value).toBe('user@example.com');
    });

    test('signup success calls auth signup endpoint', async () => {
      fetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true }),
      });

      renderPageFramework(root, 'signup');
      await Promise.resolve();

      root.querySelector('input[name="username"]').value = 'myuser';
      root.querySelector('input[name="email"]').value = 'user@example.com';
      root.querySelector('input[name="password"]').value = 'Password123!';
      root.querySelector('input[name="confirmPassword"]').value = 'Password123!';

      const form = root.querySelector('form[data-auth-form="signup"]');
      form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
      await Promise.resolve();

      expect(fetch).toHaveBeenCalledWith(
        '/api/auth/signup',
        expect.objectContaining({ method: 'POST' })
      );
    });

    test('check-email form sends resend-verification request', async () => {
      fetch.mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true }),
      });

      renderPageFramework(root, 'check-email');
      await Promise.resolve();

      root.querySelector('input[name="email"]').value = 'user@example.com';
      const form = root.querySelector('form[data-auth-form="check-email"]');
      form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
      await Promise.resolve();

      expect(fetch).toHaveBeenCalledWith(
        '/api/auth/resend-verification',
        expect.objectContaining({ method: 'POST' })
      );
    });
  });
});
