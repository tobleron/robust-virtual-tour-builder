# 1878 Recipient-Scoped Tour Links, Revocation, Expiry Override, and Analytics

## Objective
Evolve the portal access model from recipient-scoped gallery access plus plain assignments into a recipient-scoped direct-tour link system that supports:
- per-recipient direct tour links
- recipient-level default expiry
- optional per-link expiry override
- individual per-link revocation
- per-link analytics and view telemetry

The goal is to preserve reusable tours while making access control and reporting specific to each recipient-tour relationship.

## Problem Statement
The current portal model treats:
- recipients as expiring access holders
- tours as reusable library items
- assignments as many-to-many links

That is sufficient for basic gallery delivery, but it is not sufficient for the next product requirements:
- the same tour may be assigned to multiple recipients
- one recipient may need to lose access to one property/tour while keeping access to others
- brokers should lose access to an individually no-longer-marketable property without globally affecting owners or other brokers
- analytics must distinguish which recipient-specific link was viewed, not merely which global tour asset was opened

If direct-tour access remains derived only from a recipient access credential plus tour slug, then all assigned tours under that recipient share the same access lifecycle. That blocks:
- per-tour revocation
- per-tour expiry overrides
- clean per-link analytics identity

## Product Rules

### Access Precedence
Access to a direct recipient-tour link should be allowed only if all of the following are true:

1. The recipient account is active.
2. The recipient account has not reached its own expiry date.
3. The recipient-tour link is not individually revoked.
4. If the recipient-tour link has a specific expiry override, that override has not expired.
5. The underlying tour still exists and is in a publishable/assigned state.

### Expiry Rule
- Every recipient has a default expiry.
- Every recipient-tour link inherits that recipient expiry by default.
- A recipient-tour link may optionally define its own explicit expiry override.
- The effective expiry should be:
  - recipient expiry, when no override exists
  - the override expiry, when present
- Recipient expiry is still a hard upper-level gate. If the recipient itself is expired, all recipient-tour links under that recipient must be denied regardless of per-link state.

### Revocation Rule
- A recipient-tour link may be individually revoked.
- Revoking a recipient-tour link must not revoke:
  - the recipient account
  - other recipient-tour links under that recipient
  - the same underlying tour for other recipients

### Reusability Rule
- Tours remain reusable global library objects.
- A single underlying tour can be attached to many recipient-tour links, each with:
  - its own short code or direct-link identity
  - its own status
  - its own analytics
  - its own optional expiry override

## Target Data Model

### Existing Entities to Preserve
- `portal_customers` / recipients
- `portal_tours`
- existing assignment concepts where useful for migration compatibility

### New Core Entity
Introduce a dedicated recipient-tour link entity, conceptually:
- `portal_recipient_tour_links`

This entity should represent the actual access-controlled shareable link between:
- one recipient
- one tour

Suggested fields:
- `id`
- `recipient_id`
- `tour_id`
- `short_code`
- `status`
  - `active`
  - `revoked`
  - optionally `archived` or similar if needed later
- `expires_at_override` nullable
- `created_at`
- `updated_at`
- `revoked_at` nullable
- `revocation_reason` nullable
- `last_opened_at` nullable
- `open_count` or lightweight aggregate counters if desired

### Identity Strategy
Each recipient-tour link should have its own unique short-code identity.

This means:
- recipient A with tour `abc` gets one link code
- recipient B with tour `abc` gets a different link code
- both links can point to the same reusable tour asset while remaining independently controllable

This is the critical separation needed for:
- per-link revocation
- per-link analytics
- per-link expiry overrides

## URL Strategy

### Current Direction
The portal already supports short recipient-scoped URLs and short direct-tour routes.

### Future Direct Link Direction
Move toward a recipient-tour-link identity such as:
- `/u/{recipientSlug}/{linkCode}`
- or `/l/{linkCode}`

Where `linkCode` resolves directly to:
- the recipient
- the tour
- the per-link status/expiry state

Design goal:
- keep links short and professional
- avoid exposing internal storage paths or large asset URLs
- keep the address bar on a short branded route

### Recommendation
Prefer a single compact link identity per recipient-tour link rather than reconstructing direct access from:
- recipient access code
- plus tour slug

Reason:
- simpler revocation
- simpler analytics identity
- cleaner future QR code / SMS / WhatsApp sharing

## Analytics Requirements

### Why Per-Link Analytics Is Required
Analytics must answer:
- how many times was a given property/tour viewed?
- which recipient’s link was used?
- by whom in practical delivery terms (recipient identity / recipient type / broker vs owner context)?
- from which geography did views originate?
- at what times and frequencies?

### Analytics Scope
Analytics should be tied to the recipient-tour link identity, not only to the underlying tour.

Suggested event model:
- `portal_recipient_tour_link_events`

Suggested fields:
- `id`
- `recipient_tour_link_id`
- `recipient_id`
- `tour_id`
- `event_type`
  - `link_opened`
  - `viewer_loaded`
  - optionally later: `scene_changed`, `session_ended`, `cta_clicked`
- `occurred_at`
- `ip_hash` or privacy-safe visitor identifier
- `country_code`
- `city` or region when available
- `user_agent`
- `referrer`
- `session_id` or visit correlation id

### Aggregate Reporting Goals
Support reporting by:
- recipient
- recipient type
  - `Property owner`
  - `Broker`
  - `Property owner & broker`
- tour
- recipient-tour link
- date range
- geography

## Admin UX Requirements

### Assignment Creation
When assigning a tour to a recipient:
- create or reuse the recipient-tour link record intentionally
- expose whether the link is:
  - active
  - revoked
  - using inherited expiry
  - using overridden expiry

### Recipient Detail View
For one selected recipient, the admin should see assigned tours as link records, not only generic assignments.

Each row should eventually support:
- direct link copy
- open
- revoke
- restore/reactivate if supported
- set per-link expiry override
- clear override and revert to inherited recipient expiry
- analytics summary

## Recipient Slug Generation

### Goal
Recipient slugs should be:
- short
- easy to read
- auto-generated by default
- globally unique even for repeated human names

### Required Behavior
When the admin enters a friendly/display name such as:
- `Arto Kalishian`

The system should auto-generate a short slug using initials plus a numeric suffix, for example:
- `ak1`

If that slug already exists, the generator must keep searching until it finds a free slug:
- `ak2`
- `ak3`
- etc.

For repeated common names such as:
- `Ahmed Mohamed`

The generator should still produce distinct short slugs:
- `am1`
- `am2`
- `am3`

### Generation Rule
Recommended default generation rule:
1. Normalize the display name to lowercase ASCII.
2. Extract initials from the meaningful name parts.
3. Build a short base from those initials.
4. Append a numeric suffix starting from `1`.
5. Check the database for uniqueness.
6. If already used, increment the suffix until an unused slug is found.

### Constraints
- Auto-generated slugs must always be unique.
- Slugs should remain as short as possible.
- Slugs should not depend on long full-name slugification by default.
- Manual override should still be allowed when an admin wants a custom slug.

### Notes
- The uniqueness check must happen at runtime against persistent data, not only in frontend memory.
- The backend should remain the final authority for collision avoidance.
- This slug strategy should stay compatible with short, professional portal URLs.

### Tour-Centric View
For one selected tour, the admin should eventually see all recipient-tour links pointing to it, including:
- recipient name
- recipient type
- status
- effective expiry
- last opened
- views

### Bulk Assignment Compatibility
The current additive many-to-many bulk assignment workflow should remain compatible.

Bulk assignment should:
- create recipient-tour link rows for all selected recipient × selected tour combinations
- skip already-existing active links where appropriate
- define clear behavior for existing revoked links:
  - either reactivate them explicitly
  - or create a replacement link

This behavior must be decided explicitly during implementation.

## Migration Strategy

### Current State
The current system already has recipient/tour relationships through assignments.

### Required Migration
Introduce recipient-tour links without breaking existing access immediately.

Likely migration approach:
1. Add the new link table.
2. Backfill one active link row for each existing assignment.
3. Generate a unique short code for each backfilled recipient-tour link.
4. Update direct-tour resolution to use the link table.
5. Keep gallery rendering compatible while the admin UI migrates to the richer model.

### Compatibility Requirement
Existing customer galleries and assignments should remain functional after migration.
The change should be additive first, not a breaking rewrite.

## Security and Privacy Requirements
- Link codes must continue to behave like credentials and remain non-guessable.
- Per-link analytics should avoid storing raw personal data carelessly.
- IP handling should be privacy-aware; prefer hashed or minimized storage where possible.
- Revoked or expired links must fail decisively and should not fall through to asset access.

## Open Design Decisions to Resolve During Implementation
- Whether link routes should be:
  - `/u/{recipientSlug}/{linkCode}`
  - or `/l/{linkCode}`
- Whether reassigning an already revoked recipient-tour pair should:
  - reactivate the old link
  - or generate a fresh link
- Whether effective expiry should be:
  - recipient expiry unless override exists
  - or the minimum of recipient expiry and override if both are set
- Which analytics events are required in v1 versus deferred
- Whether geographic enrichment happens:
  - synchronously on request
  - asynchronously in a queue
  - or via a lightweight external lookup/cache

## Recommended Initial Implementation Scope

### Phase 1
- Add recipient-tour link table
- Backfill from existing assignments
- Generate per-link short codes
- Resolve direct-tour access through recipient-tour links
- Add per-link revocation
- Add optional per-link expiry override
- Add minimal per-link counters:
  - open count
  - last opened at

### Phase 2
- Add analytics event table
- Add geography enrichment
- Add admin reporting surfaces
- Add tour-centric analytics summaries

### Phase 3
- Add richer reporting and filters
- Add export/report download if needed
- Add charting/dashboard summaries

## Verification Expectations
- Same tour assigned to two recipients results in two distinct direct links.
- Expiring recipient A does not invalidate recipient B’s link to the same tour.
- Revoking one recipient-tour link does not affect:
  - the underlying tour
  - the recipient account globally
  - other recipients’ links
- Per-link expiry override works as intended.
- Direct link analytics are recorded per link, not just per tour.
- Existing galleries and assignments migrate without breaking.

## Notes
- This task is architectural and should likely be implemented in phases.
- It should be coordinated with portal admin UI work, backend schema changes, and direct-link routing changes.
- It supersedes the simpler “recipient access code + tour slug” model for serious production access control.
