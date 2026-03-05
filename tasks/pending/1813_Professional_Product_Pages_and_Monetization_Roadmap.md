# 1813 - Professional Product Pages and Monetization Roadmap

## Objective
Define and track the complete product-facing page architecture required to move from builder-only UX to a professional, monetizable online SaaS presence.

## Scope
- Create and launch the core website/account pages around the existing builder app.
- Ensure every page has a conversion or retention purpose.
- Keep optional pages (13, 14) deferred until core revenue loop is stable.

## Priority Order
1. Landing/Home page
2. Pricing page
3. Authentication pages (`Sign in`, `Sign up`)
4. Password recovery pages (`Forgot`, `Reset`)
5. Dashboard (projects list / recent activity)
6. Account settings
7. Billing and subscription management
8. Publish/hosting manager
9. Analytics/reporting page
10. Help/Documentation page
11. Contact/Support page
12. Legal pages (`Privacy`, `Terms`)
13. Team/Workspace management (Optional)
14. Admin/Operations panel (Optional)

## Acceptance Criteria
- [ ] All pages 1-12 exist, are routable, and use consistent design language.
- [ ] Pricing + Billing + Publish flow is connected end-to-end.
- [ ] Dashboard clearly routes users into the builder and published tours.
- [ ] Support and legal pages are publicly accessible and linked from footer/navigation.
- [ ] Optional pages 13-14 remain explicitly marked backlog until core launch KPIs are met.

## Monetization Readiness Checklist
- [ ] Subscription plans defined (limits, features, branding rules).
- [ ] Payment gateway integrated and tested for new signup and renewals.
- [ ] Publish flow tied to plan limits.
- [ ] Upgrade path visible from restricted actions.
- [ ] Basic funnel analytics enabled (visit -> signup -> trial -> paid).

## Notes
- Keep this as the umbrella planning task and split implementation into focused execution tasks per page/module.
- Builder stability remains non-negotiable; marketing/billing additions must not regress core virtual-tour authoring.
