import { describe, expect, test, beforeEach, afterEach } from 'vitest';
import { renderPageFramework, resolveAppSurface } from '../../src/site/PageFramework.js';

describe('PageFramework', () => {
  test('resolveAppSurface maps routes correctly in dev/prod', () => {
    expect(resolveAppSurface('/', 'localhost')).toBe('home');
    expect(resolveAppSurface('/', 'example.com')).toBe('home');
    expect(resolveAppSurface('/index.html', 'example.com')).toBe('home');
    expect(resolveAppSurface('/account', 'example.com')).toBe('account');
    expect(resolveAppSurface('/unknown', 'localhost')).toBe('home');
    expect(resolveAppSurface('/unknown', 'example.com')).toBe('home');
  });

  describe('renderPageFramework', () => {
    let root;

    beforeEach(() => {
      root = document.createElement('div');
      document.body.appendChild(root);
    });

    afterEach(() => {
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
  });
});
