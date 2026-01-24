# Task: Re-evaluate WebP Quality Settings

Currently, we switched the backend and frontend (to be implemented) WebP quality to 85 for performance reasons.
The user requested to switch back to 92 for further quality testing once the performance baseline is established.

## Checkpoints
- [ ] Monitor image quality in viewer with 85 quality.
- [ ] Evaluate if 92 provides a noticeable improvement for professional panoramas.
- [ ] Switch `WEBP_QUALITY` in `backend/src/api/utils.rs` back to 92.0.
- [ ] Switch frontend compression quality to 92.0 once confirmed.
