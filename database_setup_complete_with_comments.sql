-- ============================================
-- Complete Database Setup Script for IS Event Calendar
-- ============================================
-- This script sets up all required tables, columns, indexes, and sample data
-- for the IS Event Calendar application.
--
-- Instructions:
-- 1. Open pgAdmin and connect to your PostgreSQL server
-- 2. Select your database (e.g., 'foodisus' or create a new one)
-- 3. Right-click database → Query Tool
-- 4. Copy and paste this entire script
-- 5. Execute (F5 or click Execute)
--
-- Default Login Credentials:
-- Username: justmax
-- Password: admin
-- IMPORTANT: Change this password in production!
-- ============================================

-- ============================================
-- Drop Existing Tables (if they exist)
-- ============================================
-- WARNING: This will delete ALL existing data in these tables!
-- Run this script on a fresh database or backup your data first.
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS eventtypes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- Create EventTypes Table
-- ============================================
-- This table stores the categories/types of events (e.g., Career, Workshop, etc.)
-- The application uses these for filtering and categorization.
CREATE TABLE eventtypes (
    eventtypeid SERIAL PRIMARY KEY,           -- Auto-incrementing primary key
    eventtypename VARCHAR(100) NOT NULL UNIQUE -- Name of event type (must be unique)
);

-- ============================================
-- Create Events Table
-- ============================================
-- This table stores all event information.
-- It includes all fields needed for the full application functionality:
-- - Basic event info (name, description, dates, location, host)
-- - Event links/URLs (for RSVP links, registration, etc.)
-- - Custom link text (for displaying custom text instead of "Click here")
-- - Image path (for uploaded event background images)
-- - Foreign key to eventtypes table
CREATE TABLE events (
    eventid SERIAL PRIMARY KEY,                    -- Auto-incrementing primary key
    eventname VARCHAR(200) NOT NULL,               -- Event name (required)
    eventdescription TEXT,                         -- Event description (optional)
    starttime TIMESTAMP NOT NULL,                  -- Event start date/time (required)
    endtime TIMESTAMP NOT NULL,                    -- Event end date/time (required)
    eventlocation VARCHAR(200),                    -- Event location (optional)
    eventhost VARCHAR(200),                        -- Event host/organizer (optional)
    eventurl VARCHAR(500),                         -- Event URL/link (optional, for RSVP/registration)
    eventlinktext VARCHAR(200),                    -- Custom link text (optional, displays instead of "Click here")
    eventimagepath VARCHAR(500),                   -- Path to uploaded event image (optional)
    eventtypeid INTEGER NOT NULL,                  -- Foreign key to eventtypes table (required)
    CONSTRAINT fk_eventtype FOREIGN KEY (eventtypeid) 
        REFERENCES eventtypes(eventtypeid) 
        ON DELETE RESTRICT                          -- Prevents deleting event types that have events
        ON UPDATE CASCADE,                          -- Updates eventtypeid if eventtype is updated
    CONSTRAINT chk_end_after_start CHECK (endtime > starttime) -- Ensures end time is after start time
);

-- ============================================
-- Create Users Table
-- ============================================
-- This table stores admin user credentials for authentication.
-- Passwords are stored as plain text (for simplicity - change in production!)
-- In production, you should hash passwords using bcrypt or similar.
CREATE TABLE users (
    id SERIAL PRIMARY KEY,                -- Auto-incrementing primary key
    username VARCHAR(50) NOT NULL UNIQUE, -- Username (must be unique)
    password VARCHAR(50) NOT NULL         -- Password (plain text - change in production!)
);

-- ============================================
-- Create Indexes for Performance
-- ============================================
-- Indexes improve query performance for commonly searched fields.
-- They speed up queries that filter or sort by these columns.
CREATE INDEX idx_events_starttime ON events(starttime);      -- For date-based queries
CREATE INDEX idx_events_eventtypeid ON events(eventtypeid);  -- For category filtering
CREATE INDEX idx_events_eventname ON events(eventname);      -- For name searches

-- ============================================
-- Insert Default Event Types
-- ============================================
-- These event types appear in the dropdown menus when creating/editing events.
-- Using ON CONFLICT DO NOTHING allows the script to be run multiple times safely.
-- To add custom event types, use:
-- INSERT INTO eventtypes (eventtypename) VALUES ('Your Type Name') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Career') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Networking') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Workshop') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Club Meetings') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Social') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Informational') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Other') ON CONFLICT (eventtypename) DO NOTHING;

-- ============================================
-- Insert Default Admin User
-- ============================================
-- Default credentials for admin access:
-- Username: justmax
-- Password: admin
-- 
-- IMPORTANT: Change this password before deploying to production!
-- To add more users, use:
-- INSERT INTO users (username, password) VALUES ('username', 'password');
INSERT INTO users (username, password) VALUES ('justmax', 'admin');

-- ============================================
-- Verification Queries (Optional)
-- ============================================
-- Uncomment these queries to verify the setup worked correctly:

-- View all event types:
-- SELECT * FROM eventtypes ORDER BY eventtypename;

-- View all users:
-- SELECT * FROM users;

-- View events with their event types:
-- SELECT 
--     e.eventid,
--     e.eventname,
--     e.starttime,
--     e.endtime,
--     e.eventlocation,
--     e.eventhost,
--     e.eventurl,
--     e.eventlinktext,
--     et.eventtypename
-- FROM events e
-- LEFT JOIN eventtypes et ON e.eventtypeid = et.eventtypeid
-- ORDER BY e.starttime;

-- ============================================
-- Setup Complete!
-- ============================================
-- Your database is now ready to use with the IS Event Calendar application.
--
-- Next Steps:
-- 1. Update your .env file with database connection details
-- 2. Start your Node.js server (node index.js)
-- 3. Login at http://localhost:3000 with:
--    Username: justmax
--    Password: admin
-- 4. Create your first event!
--
-- Remember to change the default password in production!

