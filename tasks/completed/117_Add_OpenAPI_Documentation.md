# Task 117: Add OpenAPI Documentation for Backend API

## Priority: MEDIUM

## Context
The backend exposes 15+ API endpoints but lacks formal API documentation. This makes it harder for:
- Future developers to understand available endpoints
- Frontend code to know exact request/response shapes
- Potential API consumers to integrate

## Objective
Create OpenAPI 3.0 specification documenting all `/api/*` endpoints.

## Current Endpoints Inventory

### Telemetry (`/api/telemetry`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/log` | Log telemetry event |
| POST | `/error` | Log error event |
| POST | `/cleanup` | Clean up old logs |

### Geocoding (`/api/geocoding`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reverse` | Reverse geocode lat/lng to address |
| GET | `/stats` | Get geocoding cache stats |
| DELETE | `/cache` | Clear geocoding cache |

### Media (`/api/media`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/optimize` | Optimize single image |
| POST | `/process-full` | Full image processing pipeline |
| POST | `/transcode-video` | Transcode video to WebM |
| POST | `/extract-metadata` | Extract EXIF metadata |
| POST | `/similarity` | Batch calculate image similarity |
| POST | `/resize-batch` | Batch resize images |
| POST | `/generate-teaser` | Generate tour teaser video |

### Project (`/api/project`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/save` | Save project to disk |
| POST | `/load` | Load project from ZIP |
| POST | `/create-tour-package` | Export tour package |
| POST | `/validate` | Validate project integrity |
| POST | `/import` | Import external project |
| POST | `/calculate-path` | Calculate optimal tour path |

### Session (`/api/session`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/{session_id}/{filename}` | Serve session file |

### Utils
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/shutdown` | Trigger graceful shutdown |
| GET | `/api/quota/stats` | Get upload quota statistics |

## Acceptance Criteria
- [ ] Create `docs/openapi.yaml` with OpenAPI 3.0 specification
- [ ] Document all endpoints with request/response schemas
- [ ] Include example payloads
- [ ] Add error response schemas
- [ ] Validate spec with `swagger-cli validate docs/openapi.yaml`

## Implementation

### Example Structure
```yaml
openapi: 3.0.3
info:
  title: Remax VTB API
  version: 4.2.88
  description: Backend API for Virtual Tour Builder

servers:
  - url: http://localhost:8080
    description: Development server

paths:
  /api/media/optimize:
    post:
      summary: Optimize a single image
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                file:
                  type: string
                  format: binary
      responses:
        '200':
          description: Optimized image
          content:
            image/webp:
              schema:
                type: string
                format: binary
        '400':
          $ref: '#/components/responses/BadRequest'
        '413':
          $ref: '#/components/responses/PayloadTooLarge'

components:
  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
    PayloadTooLarge:
      description: Upload exceeds size limit
      
  schemas:
    Error:
      type: object
      properties:
        error:
          type: string
```

## Optional: Live Documentation
Consider using `utoipa` crate to auto-generate OpenAPI from Rust code:
```rust
use utoipa::OpenApi;

#[derive(OpenApi)]
#[openapi(paths(optimize_image, process_image_full))]
struct ApiDoc;
```

## Verification
1. Install swagger-cli: `npm install -g @apidevtools/swagger-cli`
2. Validate: `swagger-cli validate docs/openapi.yaml`
3. Preview: Use https://editor.swagger.io or VS Code extension

## Estimated Effort
4 hours
