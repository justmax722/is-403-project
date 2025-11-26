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
-- Email: jmaximum72@gmail.com
-- Password: admin
-- IMPORTANT: Change this password in production!
-- ============================================

-- ============================================
-- Drop Existing Tables (if they exist)
-- ============================================
-- WARNING: This will delete ALL existing data in these tables!
-- Run this script on a fresh database or backup your data first.
DROP TABLE IF EXISTS event_submissions CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS eventtypes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- NOTE: When migrating from the older schema that split out submitters, copy any
-- existing submitter rows into this new `users` table (email/password pairs with
-- role = 'S') before running the script so their submissions keep working.

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
-- This table now stores both admin and submitter credentials.
-- Everybody logs in via their email address; `role` marks admins ("A")
-- versus submitters ("S").
CREATE TABLE users (
    id SERIAL PRIMARY KEY,                        -- Auto-incrementing primary key
    email VARCHAR(255) NOT NULL UNIQUE,           -- Email (lower case preferred)
    password VARCHAR(255) NOT NULL,               -- Password (plain text - change in production!)
    role CHAR(1) NOT NULL DEFAULT 'S',            -- 'A' = admin, 'S' = submitter
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),  -- Audit for when the record was created
    CONSTRAINT chk_user_role CHECK (role IN ('A', 'S'))
);

-- ============================================
-- Create Event Submissions Table
-- ============================================
-- Stores rough drafts of submitted events so admins can review them before publishing.
CREATE TABLE event_submissions (
    submissionid SERIAL PRIMARY KEY,
    eventname VARCHAR(200) NOT NULL,
    eventdescription TEXT,
    starttime TIMESTAMP NOT NULL,
    endtime TIMESTAMP NOT NULL,
    eventlocation VARCHAR(200),
    eventhost VARCHAR(200),
    eventurl VARCHAR(500),
    eventlinktext VARCHAR(200),
    eventtypeid INTEGER NOT NULL,
    submitterid INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_submission_eventtype FOREIGN KEY (eventtypeid)
        REFERENCES eventtypes(eventtypeid)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_submission_submitter FOREIGN KEY (submitterid)
        REFERENCES users(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_event_submissions_status ON event_submissions(status);
CREATE INDEX idx_event_submissions_submitter ON event_submissions(submitterid);

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
-- Email: admin@example.com
-- Password: admin
-- 
-- IMPORTANT: Change this password before deploying to production!
-- To add more users, use:
-- INSERT INTO users (email, password, role) VALUES ('you@example.com', 'password', 'A');
INSERT INTO users (email, password, role) VALUES ('jmaximum72@gmail.com', 'admin', 'A');

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
--    Email: jmaximum72@gmail.com
--    Password: admin
-- 4. Create your first event!
--
-- Remember to change the default password in production!

