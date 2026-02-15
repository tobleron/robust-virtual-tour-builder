-- Migration to add role to users table
ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user' NOT NULL;
