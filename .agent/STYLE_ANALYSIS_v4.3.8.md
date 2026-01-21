# Style Analysis: v4.3.8+6 (old_ref) vs Current

## 1. Label Menu Styling

### OLD (v4.3.8+6) - REFERENCE:
```css
.label-menu-container {
    background-color: #ffffff !important;
    border: 1px solid var(--slate-200);
    box-shadow: var(--shadow-xl);
    border-radius: 12px;
    padding: 6px !important;
}

.label-pill {
    background: transparent;
    color: var(--slate-600);
    padding: 10px 16px;
    border-radius: 8px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
}

.label-pill:hover {
    background: var(--slate-50);
    color: var(--primary);
}

.label-pill.state-active {
    background: var(--slate-100);
    color: var(--primary-light);
}

.label-custom-section {
    border-top: 1px solid var(--slate-100);
    padding: 12px 12px 6px 12px;
}

.label-custom-input {
    background: var(--slate-50);
    border: 1px solid var(--slate-200);
    padding: 8px 12px;
    border-radius: 8px;
}

.label-btn-set {
    background: var(--primary-light);
    color: #ffffff;
    padding: 9px 12px;
    border-radius: 8px;
}

.label-btn-clear {
    background: var(--slate-100);
    color: var(--slate-600);
    padding: 9px 12px;
    border-radius: 8px;
}
```

### CURRENT - NEEDS FIXING:
- ❌ Active pill: Using `bg-primary text-white` instead of `bg-slate-100 text-primary-light`
- ❌ Hover pill: Using `hover:bg-slate-50` (CORRECT) but wrong active state
- ❌ Custom section: Using `bg-slate-50` instead of no background
- ❌ Input: Using `bg-white` instead of `bg-slate-50`

## 2. Hotspot Arrows/Chevrons

### OLD (v4.3.8+6) - REFERENCE:
```css
.hotspot-nav-btn {
    width: 70px;
    height: 70px;
    transform: translate(-50%, 0) rotateX(60deg);
    filter: drop-shadow(0 20px 10px rgba(0, 0, 0, 0.3));
    clip-path: polygon(50% 10%, 90% 40%, 90% 90%, 50% 60%, 10% 90%, 10% 40%);
}

.hotspot-delete-btn {
    top: -30px;
    right: -35px;
    width: 20px;
    height: 20px;
    background: var(--danger);
    color: white;
    border-radius: 50%;
    border: 2px solid white;
    opacity: 0;
    transition: opacity 0.3s ease-in-out 2s, visibility 0s linear 2.3s;
}

.pnlm-hotspot.flat-arrow:hover .hotspot-delete-btn {
    opacity: 1;
    transition-delay: 1.5s;
}
```

### CURRENT - NEEDS FIXING:
- ❌ Action trigger: Using `width: 24px, height: 24px` instead of `20px`
- ❌ Action trigger: Using `bg-white border-2 border-slate-200` instead of `bg-danger border-2 border-white`
- ❌ Missing delayed hover transition (1.5s delay on show, 2s on hide)
- ✅ Third chevron: Correctly restored

## 3. Scene List Context Menu

### OLD (v4.3.8+6) - REFERENCE:
```jsx
<div
  className="fixed z-[30000] bg-white rounded-2xl p-1.5 min-w-[200px] flex flex-col shadow-2xl animate-fade-in border border-slate-200"
>
  <div className="px-4 py-3 cursor-pointer text-slate-700 font-bold text-[11px] uppercase tracking-widest hover:bg-slate-50 rounded-xl">
```

### CURRENT - MATCHES ✅
- ✅ Using PopOver with white background
- ✅ Correct padding and rounded corners
- ✅ Correct hover states

## Summary of Required Changes:

1. **LabelMenu.res**:
   - Change active state from `bg-primary text-white` to `bg-slate-100 text-primary-light`
   - Change custom section from `bg-slate-50` to transparent
   - Change input from `bg-white` to `bg-slate-50`

2. **HotspotManager.res** + **viewer.css**:
   - Rename `hotspot-action-trigger` to `hotspot-delete-btn` (semantic match)
   - Change size from 24px to 20px
   - Change colors from `bg-white border-slate-200` to `bg-danger border-white`
   - Add delayed transitions (1.5s show, 2s hide)

3. **SceneActionMenu.res**:
   - Already correct! ✅
