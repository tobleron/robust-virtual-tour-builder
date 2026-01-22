# Task 303: Add SEO Structured Data (JSON-LD)

**Priority**: Medium  
**Effort**: Low (2-4 hours)  
**Impact**: Medium  
**Category**: SEO / Web Standards

## Objective

Implement structured data markup using JSON-LD to improve search engine understanding of the application and enhance SEO performance.

## Current Status

**SEO Coverage**: 70%  
**What's Implemented**:
- ✅ Meta tags (title, description, keywords)
- ✅ Open Graph (full implementation)
- ✅ Twitter Cards
- ✅ Canonical URL

**What's Missing**:
- ❌ Structured data (JSON-LD)
- ❌ robots.txt
- ❌ sitemap.xml (may not apply to SPA)

## Implementation Steps

### Phase 1: Add JSON-LD to index.html (1-2 hours)

Add structured data script to `<head>` section:

```html
<!-- Add after line 61 in index.html -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebApplication",
  "name": "Remax Virtual Tour Builder",
  "applicationCategory": "MultimediaApplication",
  "operatingSystem": "Web",
  "description": "Professional virtual tour builder with panoramic image support",
  "url": "<%= publicUrl %>/",
  "author": {
    "@type": "Person",
    "name": "<%= author %>"
  },
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "featureList": [
    "360° Panorama Viewing",
    "Interactive Hotspots",
    "Smart Upload Processing",
    "High-Performance Backend",
    "Project Export"
  ],
  "screenshot": "<%= publicUrl %>/images/og-preview.png",
  "softwareVersion": "4.3.7",
  "datePublished": "2026-01-05",
  "inLanguage": "en-US"
}
</script>
```

### Phase 2: Create robots.txt (30 minutes)

Create `public/robots.txt`:

```txt
# Remax Virtual Tour Builder - robots.txt
User-agent: *
Allow: /

# Sitemap (if created)
# Sitemap: https://yourdomain.com/sitemap.xml

# Disallow private/session directories
Disallow: /api/session/
```

### Phase 3: Add BreadcrumbList (Optional, 1 hour)

If the app has navigation hierarchy, add breadcrumb structured data:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [{
    "@type": "ListItem",
    "position": 1,
    "name": "Home",
    "item": "<%= publicUrl %>/"
  }]
}
</script>
```

### Phase 4: Add Organization Schema (Optional, 30 minutes)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Remax Virtual Tour Builder",
  "url": "<%= publicUrl %>/",
  "logo": "<%= publicUrl %>/images/logo.png",
  "contactPoint": {
    "@type": "ContactPoint",
    "contactType": "Technical Support",
    "url": "<%= publicUrl %>/"
  }
}
</script>
```

## Verification

### 1. Validate JSON-LD
- Use Google's Rich Results Test: https://search.google.com/test/rich-results
- Paste your page URL or HTML
- Verify no errors

### 2. Test robots.txt
- Access: `http://localhost:8080/robots.txt`
- Verify it loads correctly
- Use Google's robots.txt Tester (Search Console)

### 3. Schema Markup Validator
- Use: https://validator.schema.org/
- Paste JSON-LD code
- Verify valid schema

### 4. Build Test
```bash
npm run build
```

## Success Criteria

- [ ] JSON-LD WebApplication schema added to index.html
- [ ] robots.txt created in public folder
- [ ] JSON-LD validates without errors
- [ ] robots.txt accessible at /robots.txt
- [ ] Google Rich Results Test shows valid markup
- [ ] Build passes without errors
- [ ] No console errors related to structured data

## Benefits

- ✅ Improved search engine understanding
- ✅ Enhanced search result appearance
- ✅ Potential for rich snippets in Google
- ✅ Better crawlability
- ✅ Professional SEO implementation
- ✅ Compliance with web standards

## Resources

- Schema.org WebApplication: https://schema.org/WebApplication
- Google Structured Data Guide: https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data
- JSON-LD Playground: https://json-ld.org/playground/
