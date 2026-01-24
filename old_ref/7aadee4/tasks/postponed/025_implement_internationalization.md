# Task 308: Implement Internationalization (i18n) Support

**Priority**: Low (Only if targeting international markets)  
**Effort**: High (1-2 weeks)  
**Impact**: Varies (High for international markets, Low otherwise)  
**Category**: Internationalization / Accessibility

## Objective

Implement internationalization (i18n) support to enable the application to be translated into multiple languages, expanding market reach beyond English-speaking users.

## Current Status

**i18n Coverage**: 0%  
**Current Language**: English only  
**Impact**: Limits to English-speaking markets

## Business Decision Required

**Before starting this task, confirm**:
- [ ] Target markets include non-English speaking countries
- [ ] Budget allocated for translations
- [ ] Priority languages identified
- [ ] Translation resources available (professional translators or services)

**If answer is NO to above**: Close this task as "Won't Do"

## Scope

### What Needs Translation:
1. **UI Text**: Buttons, labels, menus, tooltips
2. **Messages**: Notifications, errors, warnings
3. **Documentation**: Help text, tooltips, placeholders
4. **Meta Content**: Page titles, descriptions (SEO)

### What Does NOT Need Translation:
- User-generated content (scene names, labels)
- Log messages (keep in English for debugging)
- Code comments
- Technical error codes

## Implementation Strategy

### Option A: ReScript-React-Intl (Recommended)

**Pros**:
- Type-safe translations
- ReScript integration
- Industry standard

**Cons**:
- Requires ReScript bindings
- Learning curve

### Option B: Custom Solution

**Pros**:
- Full control
- Lightweight
- No dependencies

**Cons**:
- More maintenance
- Manual type safety

## Implementation Steps (Option B - Custom)

### Phase 1: Setup Infrastructure (2-3 days)

1. **Create translation files structure**:
```
src/i18n/
├── locales/
│   ├── en.json
│   ├── es.json
│   ├── fr.json
│   ├── de.json
│   └── ...
├── I18n.res
└── I18n.resi
```

2. **Create translation JSON** (`src/i18n/locales/en.json`):
```json
{
  "common": {
    "save": "Save",
    "cancel": "Cancel",
    "delete": "Delete",
    "close": "Close"
  },
  "sidebar": {
    "title": "Virtual Tour Builder",
    "uploadButton": "Add 360 Scenes",
    "projectName": "Project Name"
  },
  "viewer": {
    "addLink": "Add Link",
    "autoPilot": "Auto Pilot",
    "category": "Toggle Category"
  },
  "notifications": {
    "uploadSuccess": "Image uploaded successfully",
    "linkCreated": "Link created",
    "projectSaved": "Project saved"
  },
  "errors": {
    "uploadFailed": "Upload failed: {error}",
    "invalidFile": "Invalid file format"
  }
}
```

3. **Create I18n module** (`src/i18n/I18n.res`):
```rescript
type locale = En | Es | Fr | De

type translations = {
  common: Js.Dict.t<string>,
  sidebar: Js.Dict.t<string>,
  viewer: Js.Dict.t<string>,
  notifications: Js.Dict.t<string>,
  errors: Js.Dict.t<string>,
}

let currentLocale = ref(En)
let translations = ref(Js.Dict.empty())

let loadTranslations = async (locale: locale): unit => {
  let localeStr = switch locale {
  | En => "en"
  | Es => "es"
  | Fr => "fr"
  | De => "de"
  }
  
  let module_ = await import(`./locales/${localeStr}.json`)
  translations := module_
  currentLocale := locale
}

let t = (key: string, ~params: option<Js.Dict.t<string>>=?, ()): string => {
  // Split key by dot: "sidebar.title"
  let parts = String.split(key, ".")
  let value = // ... lookup logic
  
  // Replace {param} placeholders
  switch params {
  | Some(p) => // ... replace logic
  | None => value
  }
}

// Shorthand
let t = t(~params=?, ())
```

### Phase 2: Extract Strings (3-5 days)

1. **Audit all hardcoded strings**:
```bash
grep -r "React.string(" src/ | grep -v ".bs.js"
```

2. **Replace hardcoded strings**:
```rescript
// Before:
<button>{React.string("Save")}</button>

// After:
<button>{React.string(I18n.t("common.save"))}</button>
```

3. **Extract all strings to en.json**

### Phase 3: Language Switcher UI (1 day)

1. **Add language selector to settings**:
```rescript
<select onChange={handleLanguageChange}>
  <option value="en">English</option>
  <option value="es">Español</option>
  <option value="fr">Français</option>
  <option value="de">Deutsch</option>
</select>
```

2. **Persist language preference**:
```rescript
// Save to localStorage
localStorage.setItem("language", localeStr)

// Load on init
let savedLang = localStorage.getItem("language")
```

### Phase 4: RTL Support (1-2 days, if needed)

For Arabic, Hebrew:

1. **Add RTL CSS**:
```css
[dir="rtl"] {
  direction: rtl;
  text-align: right;
}
```

2. **Mirror layouts**:
```css
[dir="rtl"] .sidebar {
  left: auto;
  right: 0;
}
```

### Phase 5: Professional Translation (1-2 weeks)

**Do NOT use Google Translate for production!**

Options:
1. **Professional Services**:
   - Gengo: https://gengo.com/
   - Smartling: https://www.smartling.com/
   - Lokalise: https://lokalise.com/

2. **Freelance Translators**:
   - Upwork
   - Fiverr
   - ProZ.com

3. **Community Translation**:
   - Crowdin: https://crowdin.com/

**Budget**: ~$0.10-0.20 per word × word count

### Phase 6: Testing (2-3 days)

1. Test each language:
   - All UI text displays correctly
   - No truncation or overflow
   - Proper character encoding
   - Date/time formatting
   - Number formatting

2. Test RTL (if applicable):
   - Layout mirrors correctly
   - Icons flip appropriately
   - Text alignment correct

## Verification

1. Language switcher works
2. All UI text translates
3. No hardcoded strings remain
4. Translations are accurate (native speaker review)
5. Layout works in all languages
6. Build passes: `npm run build`

## Success Criteria

- [ ] I18n infrastructure implemented
- [ ] All UI strings extracted to translation files
- [ ] At least 2 languages fully translated
- [ ] Language switcher UI implemented
- [ ] Language preference persisted
- [ ] RTL support (if applicable)
- [ ] Professional translations completed
- [ ] Native speaker review completed
- [ ] All languages tested
- [ ] Documentation updated

## Priority Languages (Example)

Based on real estate market:
1. **English** (en) - Primary
2. **Spanish** (es) - Large market
3. **French** (fr) - Canada, Europe
4. **German** (de) - Europe
5. **Chinese** (zh) - Growing market
6. **Arabic** (ar) - Middle East (requires RTL)

## Benefits

- ✅ Access to international markets
- ✅ Increased user base
- ✅ Competitive advantage
- ✅ Better user experience for non-English speakers
- ✅ Professional appearance
- ✅ Accessibility improvement

## Risks if Not Implemented

- ⚠️ Limited to English-speaking markets
- ⚠️ Missed revenue opportunities
- ⚠️ Competitive disadvantage in international markets

## Resources

- React-Intl: https://formatjs.io/docs/react-intl/
- i18next: https://www.i18next.com/
- Locale Codes: https://www.science.co.il/language/Locale-codes.php
- RTL Guide: https://rtlstyling.com/
