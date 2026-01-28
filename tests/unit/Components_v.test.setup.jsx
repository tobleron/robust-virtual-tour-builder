// @efficiency: infra-adapter
import { vi } from 'vitest';
import React from 'react';

const MockComp = (props) => {
    return props.children || null;
};
MockComp.make = MockComp;

const MockButton = (props) => {
    return React.createElement('button', {
        onClick: props.onClick,
        className: props.className,
        disabled: props.disabled,
        'data-variant': props.variant,
        'data-size': props.size
    }, props.children);
};
MockButton.make = MockButton;

vi.mock('sonner', () => {
    return {
        toast: {
            success: vi.fn(),
            error: vi.fn(),
            warning: vi.fn(),
            info: vi.fn()
        }
    };
});

vi.mock('../../src/components/ui/Shadcn.bs.js', () => {
    return {
        Button: { make: MockButton },
        Tooltip: { make: MockComp, Trigger: { make: MockComp }, Content: { make: MockComp }, Provider: { make: MockComp } },
        Popover: { make: MockComp, Trigger: { make: MockComp }, Content: { make: MockComp }, Anchor: { make: MockComp } },
        DropdownMenu: {
            make: MockComp,
            Trigger: { make: MockComp },
            Content: { make: MockComp },
            Item: { make: MockButton },
            Label: { make: MockComp },
            Group: { make: MockComp },
            RadioGroup: { make: MockComp },
            RadioItem: { make: MockButton },
            Separator: { make: () => React.createElement('hr') },
            Sub: { make: MockComp },
            SubTrigger: { make: MockComp },
            SubContent: { make: MockComp },
        },
        ContextMenu: {
            make: MockComp,
            Trigger: { make: MockComp },
            Content: { make: MockComp },
            Item: { make: MockButton },
            Separator: { make: () => React.createElement('hr') },
        },
        Sonner: {
            make: MockComp,
        }
    };
});

// Lucide Icons Mock
vi.mock('../../src/components/ui/LucideIcons.bs.js', () => {
    return {
        Plus: () => React.createElement('div', { 'data-testid': 'icon-plus' }),
        X: () => React.createElement('div', { 'data-testid': 'icon-x' }),
        Square: () => React.createElement('div', { 'data-testid': 'icon-square' }),
        Play: () => React.createElement('div', { 'data-testid': 'icon-play' }),
        Navigation: () => React.createElement('div', { 'data-testid': 'icon-navigation' }),
        Trash2: () => React.createElement('div', { 'data-testid': 'icon-trash2' }),
        ChevronRight: () => React.createElement('div', { 'data-testid': 'icon-chevron-right' }),
        ChevronLeft: () => React.createElement('div', { 'data-testid': 'icon-chevron-left' }),
        CircleHelp: () => React.createElement('div', { 'data-testid': 'icon-help' }),
        Hash: () => React.createElement('div', { 'data-testid': 'icon-hash' }),
    };
});
