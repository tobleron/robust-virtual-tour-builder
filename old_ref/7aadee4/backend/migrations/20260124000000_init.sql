-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY NOT NULL, -- UUID
    email TEXT UNIQUE NOT NULL,
    google_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    avatar_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY NOT NULL, -- UUID
    user_id TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT 'Untitled Tour',
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    project_data TEXT NOT NULL DEFAULT '{}', -- Store JSON as TEXT in SQLite
    preview_image_url TEXT,
    is_public INTEGER DEFAULT 0, -- 0 for false, 1 for true
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);

-- Trigger for updated_at (SQLite specific)
CREATE TRIGGER IF NOT EXISTS update_projects_timestamp 
AFTER UPDATE ON projects
FOR EACH ROW
BEGIN
    UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;
