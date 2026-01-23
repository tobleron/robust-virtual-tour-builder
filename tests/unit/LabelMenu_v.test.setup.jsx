import { vi } from 'vitest';
import React from 'react';

// Polyfill ResizeObserver for JSDOM
globalThis.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};

// Common Shadcn Mocks
vi.mock('../../src/components/ui/Shadcn.bs.js', () => {
  const MockComp = ({ children }) => children;
  const DropdownMenu = {
    make: MockComp,
    Trigger: { make: MockComp },
    Content: { make: MockComp },
    Item: { make: MockComp },
    Label: { make: MockComp },
    Group: { make: MockComp },
    Separator: { make: () => null },
  };
  const Tooltip = {
    make: MockComp,
    Trigger: { make: MockComp },
    Content: { make: MockComp },
    Provider: { make: MockComp },
  };
  const Popover = {
    make: MockComp,
    Trigger: { make: MockComp },
    Content: { make: MockComp },
    Anchor: { make: MockComp },
  };
  return {
    DropdownMenu,
    Tooltip,
    Popover,
    Button: { 
      make: ({children, onClick, className}) => 
        React.createElement('button', { onClick, className }, children) 
    },
    ContextMenu: { make: MockComp },
  };
});

// Lucide Icons Mock
vi.mock('../../src/components/ui/LucideIcons.bs.js', () => {
  return {
    Home: () => React.createElement('div', { 'data-testid': 'icon-home' }),
    FilePlus: () => React.createElement('div', { 'data-testid': 'icon-file-plus' }),
    Save: () => React.createElement('div', { 'data-testid': 'icon-save' }),
    FolderOpen: () => React.createElement('div', { 'data-testid': 'icon-folder-open' }),
    Info: () => React.createElement('div', { 'data-testid': 'icon-info' }),
    Download: () => React.createElement('div', { 'data-testid': 'icon-download' }),
    Film: () => React.createElement('div', { 'data-testid': 'icon-film' }),
    Camera: () => React.createElement('div', { 'data-testid': 'icon-camera' }),
    Plus: () => React.createElement('div', { 'data-testid': 'icon-plus' }),
    X: () => React.createElement('div', { 'data-testid': 'icon-x' }),
    Square: () => React.createElement('div', { 'data-testid': 'icon-square' }),
    Play: () => React.createElement('div', { 'data-testid': 'icon-play' }),
    Hash: () => React.createElement('div', { 'data-testid': 'icon-hash' }),
    Navigation: () => React.createElement('div', { 'data-testid': 'icon-navigation' }),
    FastForward: () => React.createElement('div', { 'data-testid': 'icon-fast-forward' }),
    ChevronRight: () => React.createElement('div', { 'data-testid': 'icon-chevron-right' }),
    Trash2: () => React.createElement('div', { 'data-testid': 'icon-trash2' }),
    Images: () => React.createElement('div', { 'data-testid': 'icon-images' }),
    GripVertical: () => React.createElement('div', { 'data-testid': 'icon-grip' }),
    Link: () => React.createElement('div', { 'data-testid': 'icon-link' }),
    MoreVertical: () => React.createElement('div', { 'data-testid': 'icon-more' }),
    Unlink: () => React.createElement('div', { 'data-testid': 'icon-unlink' }),
    CircleCheck: () => React.createElement('div', { 'data-testid': 'icon-check' }),
    CircleAlert: () => React.createElement('div', { 'data-testid': 'icon-alert' }),
    TriangleAlert: () => React.createElement('div', { 'data-testid': 'icon-warning' }),
    Sun: () => React.createElement('div', { 'data-testid': 'icon-sun' }),
  };
});

// VersionData Mock
vi.mock('../../src/utils/VersionData.bs.js', () => {
  return {
    version: '4.4.7',
    buildInfo: 'Stable Release',
  };
});