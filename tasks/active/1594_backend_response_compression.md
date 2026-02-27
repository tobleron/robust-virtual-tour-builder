# Task: Backend Response Compression & ETag Conditional Requests

## Objective
Enable server-side response compression (gzip/brotli) and implement ETag-based conditional request handling to reduce bandwidth usage and improve response times for API and asset serving.

## Problem Statement
The Actix-web backend does not currently apply response compression middleware. All API responses (including large project JSON payloads, validation reports, and error bodies) are sent uncompressed. For a 500-scene project save response, the JSON payload can be 500KB+ uncompressed but ~50KB compressed. Additionally, there are no ETag/Last-Modified headers on served media files, so browser requests always download full files even when content hasn't changed.

## Acceptance Criteria
- [ ] Add `actix-web-codegen` or `actix_web::middleware::Compress` with Brotli (preferred) and Gzip fallback
- [ ] Configure minimum compression threshold: only compress responses > 1KB
- [ ] Exclude already-compressed content types (images, WebP, zip archives) from compression
- [ ] Implement ETag generation for served media files based on file hash or last-modified timestamp
- [ ] Return `304 Not Modified` for conditional requests with matching `If-None-Match` header
- [ ] Add `Cache-Control` headers for static assets: `public, max-age=31536000, immutable` for hashed assets
- [ ] Add `Vary: Accept-Encoding` header to compressed responses for CDN compatibility

## Technical Notes
- **Files**: `backend/src/startup.rs`, `backend/src/api/media/serve.rs`
- **Pattern**: Actix-web `Compress` middleware with content-type filters
- **Risk**: Low — standard HTTP best practice; widely supported
- **Measurement**: API response sizes should decrease 60-80%; media file requests should show 304s on reload
