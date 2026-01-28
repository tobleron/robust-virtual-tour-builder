# SYSTEM PROPOSAL REVIEW: Autonomous Efficiency Engine

I am considering replacing our static 360-line code limit with a dynamic "Efficiency Engine" to optimize autonomous coding in this project (Rust & ReScript).

I have a Node.js script ready to implement the logic below, but before I deploy it, I need you to analyze this system against our CURRENT codebase and architecture.

## 1. The Core Concept
The goal is "Zero-Intervention Efficiency." Instead of a hard limit, we calculate a `MaxLOC` (Max Lines of Code) for every file based on two factors:
1.  **Cognitive Density:** How hard is the code to read? (Logic, Nesting, Dependencies).
2.  **Module Purpose:** What is the file doing? (UI is allowed to be long; Algorithms must be short).

## 2. The Logic & Formulas

### A. The "Splitting" Formula (Dynamic Limit)
The script calculates `L_max` for every file. If `Current_LOC > L_max`, the build fails.

Formula:
L_max = floor( (250 * P_mod) / (1 + (0.05 * D_nest) + (2.0 * L_den) - (0.5 * H_den) - (0.3 * S_den)) )

Variables:
- **Base:** 250 lines (Safe context window).
- **P_mod:** Purpose Modifier (See Table below).
- **D_nest:** Max Indentation Depth (e.g., 4).
- **L_den (Logic Density):** Ratio of logic keywords (`if`, `match`, `loop`, `unsafe`, `rec`) to total lines.
- **H_den (HTML Density):** Ratio of JSX/HTML lines to total lines (Bonus).
- **S_den (Style Density):** Ratio of CSS/Style lines to total lines (Bonus).

### B. The "Consolidation" Formula (Smart Merging)
The script scans folders for "Fragmentation." It suggests merging ONLY if files share the same `@agent-type`.

Formula:
Merge_Score = (Count_of_Type * 10) / (Avg_LOC + 1)

- If Score > 1.5: TRIGGER MERGE (Too many small files of the same type).
- If Score < 1.5: IGNORE.

## 3. The "Master Function" Table (P_mod)
You (the Agent) are required to add a header `// @agent-type: [TERM]` to every file. The script uses this to set the Multiplier (`P_mod`).

| Group | Term | P_mod | Usage Context |
| :--- | :--- | :--- | :--- |
| **Presentation** | `view-layout` | 1.8x | High-level Page Wrappers |
| | `ui-primitive` | 1.6x | Atomic UI (Buttons, Inputs) |
| | `ui-composite` | 1.3x | Molecules (Search bar, Cards) |
| | `style-theme` | 2.0x | Config, CSS Variables |
| | `anim-driver` | 1.1x | Animations (Framer/CSS) |
| **Logic (Strict)** | `core-algorithm`| 0.5x | Complex Math, Parsing, Pathfinding |
| | `biz-rule` | 0.7x | Domain Conditions, Permissions |
| | `state-reducer` | 0.6x | Redux/Context Reducers |
| | `hook-logic` | 0.7x | Custom React Hooks |
| | `validator` | 0.9x | Zod Schemas, Regex |
| **Data/Infra** | `data-model` | 1.5x | Structs, Types, Interfaces |
| | `api-client` | 1.0x | Fetch wrappers, Endpoints |
| | `config-static` | 1.5x | Constants, Env Vars |
| | `helper` | 1.0x | Generic Utilities |
| **Rust Specifics** | `macro-def` | 0.4x | `macro_rules!` definitions |
| | `trait-impl` | 0.8x | Trait Implementations |
| | `wasm-bridge` | 0.9x | Wasm Bindgen Glue |

## 4. Your Task (Risk & Suitability Assessment)

Using your knowledge of the current `robust-virtual-tour-builder` codebase (Rust/ReScript), please answer:

1.  **Suitability Check:** Does this classification table cover our specific needs? Are there files in our current project that do NOT fit into these categories? (e.g., specific 3D engine logic, image processing?).
2.  **The "ReScript" Risk:** ReScript relies heavily on piping (`->`). The formula counts logic keywords but doesn't explicitly penalize pipe chains. Is this a risk for us, or are pipe chains safe enough to treat as linear?
3.  **Migration Friction:** If we apply this today, roughly what percentage of our existing files would likely FAIL the new dynamic limits? (Estimate based on your memory of our complex modules).
4.  **Gaming the System:** Can you identify a way this system might accidentally encourage "bad" coding (e.g., splitting files arbitrarily just to satisfy the math)?

Output your assessment and a final verdict: **PROCEED** or **MODIFY**.


/**
 * ROBUST VIRTUAL TOUR BUILDER - EFFICIENCY ENGINE
 * Enforces dynamic line limits and semantic consolidation.
 */

const fs = require('fs');
const path = require('path');

// =============================================================================
// 1. THE CONFIGURATION (The "Brain")
// =============================================================================

const BASE_LIMIT = 250; // The "Safe Context" baseline

// The Master Function Table
const TYPE_DEFINITIONS = {
    // --- Group A: Presentation (High Tolerance) ---
    "view-layout":    { multiplier: 1.8, role: "ui",  desc: "High-level page wrappers" },
    "ui-primitive":   { multiplier: 1.6, role: "ui",  desc: "Atomic UI (Button, Input)" },
    "ui-composite":   { multiplier: 1.3, role: "ui",  desc: "Molecules (Search bar)" },
    "style-theme":    { multiplier: 2.0, role: "ui",  desc: "CSS vars, Config" },
    "anim-driver":    { multiplier: 1.1, role: "ui",  desc: "Animation variants" },
    "story-mock":     { multiplier: 1.5, role: "util", desc: "Storybook/Mocks" },

    // --- Group B: Business Logic (Strict Tolerance) ---
    "core-algorithm": { multiplier: 0.5, role: "logic", desc: "Complex math/parsing" },
    "biz-rule":       { multiplier: 0.7, role: "logic", desc: "Domain logic/Conditions" },
    "state-reducer":  { multiplier: 0.6, role: "logic", desc: "Redux/Context reducers" },
    "hook-logic":     { multiplier: 0.7, role: "logic", desc: "Custom React Hooks" },
    "middleware":     { multiplier: 0.8, role: "logic", desc: "Request interception" },
    "validator":      { multiplier: 0.9, role: "logic", desc: "Zod/Regex schemas" },

    // --- Group C: Data & Infra (Medium Tolerance) ---
    "data-model":     { multiplier: 1.5, role: "data", desc: "Structs/Interfaces" },
    "api-client":     { multiplier: 1.0, role: "data", desc: "Fetch wrappers" },
    "db-migration":   { multiplier: 1.2, role: "data", desc: "SQL Schemas" },
    "dto-mapper":     { multiplier: 1.1, role: "util", desc: "Data transformers" },
    "config-static":  { multiplier: 1.5, role: "util", desc: "Constants/Env" },
    "helper":         { multiplier: 1.0, role: "util", desc: "Generic utilities" },

    // --- Group D: Rust Specifics ---
    "macro-def":      { multiplier: 0.4, role: "meta", desc: "macro_rules! (High Risk)" },
    "trait-impl":     { multiplier: 0.8, role: "logic", desc: "Trait implementations" },
    "wasm-bridge":    { multiplier: 0.9, role: "logic", desc: "Wasm glue code" }
};

// =============================================================================
// 2. THE ANALYZER (Metrics Extraction)
// =============================================================================

function analyzeFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    
    // 1. Extract Agent Type
    const typeMatch = content.match(/\/\/ @agent-type: ([\w-]+)/);
    const type = typeMatch ? typeMatch[1] : "UNKNOWN";
    const typeDef = TYPE_DEFINITIONS[type] || { multiplier: 1.0, role: "unknown" };

    // 2. Count "Real" Lines (Skip empty & comments)
    const codeLines = lines.filter(l => {
        const trimmed = l.trim();
        return trimmed.length > 0 && !trimmed.startsWith('//') && !trimmed.startsWith('/*');
    });
    const loc = codeLines.length;

    // 3. Logic Density (L_den)
    // Keywords that indicate "thinking" vs "listing"
    const logicKeywords = [
        'if', 'else', 'match', 'switch', 'loop', 'for', 'while', 
        'unsafe', 'try', 'catch', 'raise', 'rec', 'mut', 'await'
    ];
    const logicCount = (content.match(new RegExp(`\\b(${logicKeywords.join('|')})\\b`, 'g')) || []).length;
    const l_den = loc > 0 ? logicCount / loc : 0;

    // 4. HTML Density (H_den)
    // React/ReScript JSX or Rust macros like html! or view!
    const htmlLines = lines.filter(l => /<[a-zA-Z]/.test(l) || /html!|view!/.test(l)).length;
    const h_den = loc > 0 ? htmlLines / loc : 0;

    // 5. Style Density (S_den)
    // CSS-in-JS, Tailwind classes, or style! macros
    const styleLines = lines.filter(l => /style!|css`|className|ReactDOM\.Style/.test(l)).length;
    const s_den = loc > 0 ? styleLines / loc : 0;

    // 6. Max Nesting (D_nest)
    // Assumes 2 or 4 space indentation. Measures max whitespace at start of line.
    const maxIndent = lines.reduce((max, line) => {
        const spaces = line.match(/^ +/);
        return spaces ? Math.max(max, spaces[0].length) : max;
    }, 0);
    const d_nest = Math.round(maxIndent / 2); // Approximate depth

    return {
        filePath,
        fileName: path.basename(filePath),
        folder: path.dirname(filePath),
        type,
        typeDef,
        loc,
        metrics: { l_den, h_den, s_den, d_nest }
    };
}

// =============================================================================
// 3. THE CALCULATOR (The Formula)
// =============================================================================

function calculateLimit(fileData) {
    const { loc, typeDef, metrics } = fileData;
    const { l_den, h_den, s_den, d_nest } = metrics;
    const P_mod = typeDef.multiplier;

    // --- THE FORMULA ---
    // Denominator = 1 + (Drag from Nesting) + (Drag from Logic) - (Bonus from HTML) - (Bonus from CSS)
    let drag = 1 + (0.05 * d_nest) + (2.0 * l_den) - (0.5 * h_den) - (0.3 * s_den);
    
    // Safety clamp: Drag cannot be less than 0.5 (to prevent infinite lines)
    if (drag < 0.5) drag = 0.5;

    const maxLimit = Math.floor((BASE_LIMIT * P_mod) / drag);

    return {
        allowed: maxLimit,
        current: loc,
        pass: loc <= maxLimit,
        drag: drag.toFixed(2)
    };
}

// =============================================================================
// 4. THE VALIDATOR (Heuristics)
// =============================================================================

function validateType(fileData) {
    const { type, metrics } = fileData;
    
    // Rule 1: UI components must have HTML
    if ((type === 'ui-component' || type === 'view-layout') && metrics.h_den === 0) {
        return "Tagged as UI but contains zero HTML/JSX.";
    }
    
    // Rule 2: Data models should not have heavy logic
    if (type === 'data-model' && metrics.l_den > 0.1) {
        return `Tagged as Data Model but Logic Density is high (${(metrics.l_den*100).toFixed(0)}%).`;
    }

    // Rule 3: Unknown types are forbidden
    if (fileData.typeDef.role === 'unknown') {
        return `Unknown agent-type: '${type}'. Use a valid term from the Standard.`;
    }

    return null; // Valid
}

// =============================================================================
// 5. THE CONSOLIDATOR (Semantic Clustering)
// =============================================================================

function checkFragmentation(filesInFolder) {
    // Group files by @agent-type
    const clusters = {};
    
    filesInFolder.forEach(f => {
        if (!clusters[f.type]) clusters[f.type] = [];
        clusters[f.type].push(f);
    });

    const suggestions = [];

    for (const [type, files] of Object.entries(clusters)) {
        if (files.length < 2) continue; // Need at least 2 files to merge

        // Calculate Cluster Stats
        const avgSize = files.reduce((sum, f) => sum + f.loc, 0) / files.length;
        const count = files.length;
        
        // Simulating "Internal Imports" (In a real parser, we'd regex for imports of sibling filenames)
        // For now, we assume high fragmentation if count is high and size is small.
        
        // --- THE MERGE FORMULA ---
        // Score = (Count * 1.5) / (AvgSize / 100) -> Normalized
        // If files are tiny (e.g. 20 lines) and many (5), score skyrockets.
        const mergeScore = (count * 10) / (avgSize + 1); 

        // Threshold: If Score > 1.5, suggest merge
        if (mergeScore > 1.5 && type !== 'UNKNOWN') {
            const fileNames = files.map(f => f.fileName).join(', ');
            suggestions.push({
                type,
                score: mergeScore.toFixed(2),
                message: `Consolidate ${count} small '${type}' files (${fileNames}) into one module.`
            });
        }
    }
    return suggestions;
}

// =============================================================================
// 6. MAIN EXECUTION
// =============================================================================

function walkDir(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    files.forEach(file => {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) {
            if (file !== 'node_modules' && file !== 'target' && file !== '.git' && file !== 'lib') {
                walkDir(filePath, fileList);
            }
        } else {
            if (filePath.endsWith('.rs') || filePath.endsWith('.res') || filePath.endsWith('.js') || filePath.endsWith('.ts')) {
                fileList.push(filePath);
            }
        }
    });
    return fileList;
}

function run() {
    const rootDir = process.cwd(); // Or specific src folder
    const allFiles = walkDir(rootDir);
    let hasError = false;

    console.log("\n🚀 STARTING EFFICIENCY ENGINE CHECK...\n");

    // 1. Check Limits & Validation
    const processedFiles = allFiles.map(fp => analyzeFile(fp));
    const folders = {};

    processedFiles.forEach(file => {
        // Group for step 2
        if (!folders[file.folder]) folders[file.folder] = [];
        folders[file.folder].push(file);

        // Run Checks
        const limits = calculateLimit(file);
        const validationError = validateType(file);

        if (validationError) {
            console.error(`❌ [VALIDATION FAIL] ${file.fileName}: ${validationError}`);
            hasError = true;
            return;
        }

        if (!limits.pass) {
            console.error(`❌ [SIZE FAIL] ${file.fileName} (${file.type})`);
            console.error(`   Lines: ${limits.current} / ${limits.allowed} (Drag: ${limits.drag})`);
            console.error(`   Action: Split this module.`);
            hasError = true;
        } else {
            // Optional: Verbose success
            // console.log(`✅ ${file.fileName}: ${limits.current}/${limits.allowed}`);
        }
    });

    // 2. Check Fragmentation (Semantic Clustering)
    console.log("\n🧩 CHECKING FRAGMENTATION...");
    Object.keys(folders).forEach(folderPath => {
        const suggestions = checkFragmentation(folders[folderPath]);
        if (suggestions.length > 0) {
            console.warn(`\n📂 Folder: ${path.relative(rootDir, folderPath)}`);
            suggestions.forEach(s => {
                console.warn(`   ⚠️  [MERGE SUGGESTION] Score: ${s.score} | Type: ${s.type}`);
                console.warn(`      ${s.message}`);
            });
        }
    });

    if (hasError) {
        console.log("\n🔴 BUILD FAILED: Fix efficiency violations above.");
        process.exit(1);
    } else {
        console.log("\n🟢 EFFICIENCY CHECK PASSED.");
    }
}

run();