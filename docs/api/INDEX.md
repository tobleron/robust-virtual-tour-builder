# API Reference

Backend API specification and documentation.

---

## Documents

### [OpenAPI Specification](./openapi.yaml)
Complete REST API specification in OpenAPI 3.0 format.

**Endpoints:**
- Authentication (`/api/auth/*`)
- Media processing (`/api/media/*`)
- Project management (`/api/project/*`)
- Geocoding (`/api/geocoding/*`)

---

## API Conventions

### Authentication
All API endpoints except health checks require JWT authentication via `Authorization: Bearer <token>` header.

### Rate Limiting
API is rate-limited to 30 requests/second per IP. Rate limit headers are included in responses:
```http
X-RateLimit-Limit: 30
X-RateLimit-Remaining: 25
X-RateLimit-Reset: 1234567890
```

### Error Responses
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": {}
  }
}
```

---

## Related Documentation

- **[Security - Authentication](../security/authentication.md)** - Auth flow and risk model
- **[Security - Rate Limits](../security/rate_limits.md)** - Rate limiting policies
- **[Operations - Deployment](../operations/deployment.md)** - API deployment

---

**Last Updated:** March 19, 2026
