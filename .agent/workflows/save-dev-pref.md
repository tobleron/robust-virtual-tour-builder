---
description: Preserve distinct developer preferences or feature requests.
---

# Save Developer Preference Workflow

Follow these steps whenever a distinct developer preference or feature request is detected in the prompt.

## 1. Identify Specification
1.  Extract the full specification of the preference or feature request.
2.  Include details about UI style, code design, architecture, or any other developer-centric requirements.

## 2. Document Preference
1.  Create a new file in the `dev_prefs/` directory.
2.  **Naming Convention**: `pref_YYYYMMDD_HHMMSS_brief_description.md` (use the current timestamp).
3.  **Content Format**:
    - **Title**: Descriptive title of the preference/feature.
    - **Date**: Current date and time.
    - **Type**: (e.g., UI Style, Architecture, Code Design, Feature Request).
    - **Specification**: Detailed description of the request.
    - **Context**: (Optional) Brief mention of why/where this was requested if relevant to implementation.

## 3. Confirmation
1.  Verify the file is correctly saved in the `dev_prefs/` folder.
2.  Inform the user that the preference has been documented and preserved.
