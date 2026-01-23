# Task 030: Implement Supabase Infrastructure & Database Schema

**Priority**: High
**Effort**: Medium (6-8 hours)
**Impact**: Critical
**Category**: Infrastructure / Backend

## Objective

Transition the application from transient `/tmp` sessions to a permanent PostgreSQL database using Supabase. This provides the foundation for user accounts and persistent project storage.

## Current Status

**Storage Strategy**: Transient sessions in server `/tmp` directory.
**Risk**: Data loss on server restart or 24-hour cleanup cycle. No user ownership of data.

## Implementation Steps

### Phase 1: Supabase Project Setup
1. Create a new Supabase project.
2. Configure environment variables in `.env.development` and `.env.production`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY` (for backend only)

### Phase 2: Database Schema Design
Execute the following SQL in the Supabase SQL Editor:

```sql
-- Users table is handled by Supabase Auth (auth.users)

-- Projects Table
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  project_data JSONB NOT NULL,
  preview_image_url TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Project Assets (Optional: for granular tracking)
CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  file_type TEXT,
  size_bytes BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own projects" ON projects
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own projects" ON projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects" ON projects
  FOR UPDATE USING (auth.uid() = user_id);
```

### Phase 3: Supabase Storage Configuration
1. Create a bucket named `project-assets`.
2. Configure RLS for the bucket to allow users to upload/download only within their own folder (`user_id/*`).

## Success Criteria

- [ ] Supabase project active and connected.
- [ ] Database tables created with correct RLS policies.
- [ ] Storage bucket configured for asset persistence.
- [ ] Environment variables documented in `.env.example`.
