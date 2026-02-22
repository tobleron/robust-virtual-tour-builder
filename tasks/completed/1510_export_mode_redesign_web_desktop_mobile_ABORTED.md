# 1510 - Export Mode Redesign (Web-Only + Desktop 2K Blob + Mobile HD)

## Objective
Redesign the export package into three explicit delivery modes:
1. `web_only/` with all required assets/libs and all three resolutions (4K, 2K, HD) for website/webserver integration.
2. `desktop/` as 2K-only standalone HTML using embedded scene blobs for direct local opening.
3. `mobile_hd/` as HD-only file-based package designed for mini webserver usage with instructions.

## Scope
- Frontend exporter template payload: add dedicated desktop 2K blob-capable HTML field.
- Backend multipart parsing: accept new desktop HTML field and scene policy field.
- Backend package builder: emit three-mode folder structure and root launcher links.
- Desktop package: include only 2K tour (blob/data-uri scenes), with local open guidance.
- Mobile package: include only HD assets and local mini webserver instructions.

## Acceptance Criteria
- [ ] Root export includes `web_only/`, `desktop/`, and `mobile_hd/`.
- [ ] `web_only/` contains 4K, 2K, and HD tour pages plus required assets/libs.
- [ ] `desktop/index.html` opens with 2K tour using embedded scene data and no server requirement.
- [ ] `mobile_hd/` contains HD-only tour and clear local server README.
- [ ] Frontend and backend compile checks pass.
