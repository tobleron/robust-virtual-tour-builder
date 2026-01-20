# Task 276: Refactor UploadReport.res Inline Styles

## 🎯 Objective
Migrate all remaining inline styles from the `UploadReport.res` component to a dedicated CSS file, following the project's Separation of Concerns protocol.

---

## 🛠️ Step-by-Step Implementation

### Step 1: Create Dedicated CSS File
- Create `css/components/upload-report.css`.
- Import it in the main stylesheet if necessary (check `css/style.css`).

**Verification**:
- Check if file is loaded in dev tools.

### Step 2: Define Semantic Classes
- Extract all style strings from `UploadReport.res`.
- Create semantic CSS classes (e.g., `.report-container`, `.report-card`, `.report-label`, `.badge-excellent`).

**Verification**:
- Run `npm run build` to verify CSS validity.

### Step 3: Update `UploadReport.res`
- Replace `style="..."` attributes in the generated HTML strings with `className="..."`.
- Ensure all dynamic logic (like specific color backgrounds for badges) is handled via class toggling or CSS variables.

**Verification**:
- Trigger an upload or view the upload report.
- Verify visual appearance matches the previous state exactly.

---

## 🧪 Final Verification
- Run `npm run build`.
- Verify the report UI is responsive and styled correctly.
