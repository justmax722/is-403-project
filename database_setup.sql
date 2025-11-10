-- ============================================
-- Database Setup Script for IS-403 Project
-- Run this script in pgAdmin PostgreSQL
-- ============================================

-- Drop tables if they exist (in reverse order due to foreign keys)
-- WARNING: This will delete all existing data!
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS eventtypes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- Create EventTypes Table
-- ============================================
CREATE TABLE eventtypes (
    eventtypeid SERIAL PRIMARY KEY,
    eventtypename VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================
-- Create Events Table
-- ============================================
CREATE TABLE events (
    eventid SERIAL PRIMARY KEY,
    eventname VARCHAR(200) NOT NULL,
    eventdescription TEXT,
    starttime TIMESTAMP NOT NULL,
    endtime TIMESTAMP NOT NULL,
    eventlocation VARCHAR(200),
    eventhost VARCHAR(200),
    eventtypeid INTEGER NOT NULL,
    CONSTRAINT fk_eventtype FOREIGN KEY (eventtypeid) 
        REFERENCES eventtypes(eventtypeid) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT chk_end_after_start CHECK (endtime > starttime)
);

-- ============================================
-- Create Users Table (for authentication)
-- ============================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(50) NOT NULL
);

-- ============================================
-- Insert Event Types
-- ============================================
-- Using INSERT ... ON CONFLICT DO NOTHING to avoid duplicates
-- This allows the script to be run multiple times safely
-- These event types will appear in the dropdown on the create/edit event pages

INSERT INTO eventtypes (eventtypename) VALUES ('Career') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Networking') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Workshop') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Club Meetings') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Social') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Informational') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Other') ON CONFLICT (eventtypename) DO NOTHING;

-- ============================================
-- Optional: Add Custom Event Types
-- ============================================
-- To add your own event types, use this format:
-- INSERT INTO eventtypes (eventtypename) VALUES ('Your Event Type Name') ON CONFLICT (eventtypename) DO NOTHING;

-- ============================================
-- Optional: Update Existing Event Type Name
-- ============================================
-- To update an existing event type name:
-- UPDATE eventtypes SET eventtypename = 'New Name' WHERE eventtypename = 'Old Name';

-- ============================================
-- Optional: Delete Event Type (use with caution!)
-- ============================================
-- WARNING: Only delete if no events are using this type!
-- Check first: SELECT COUNT(*) FROM events WHERE eventtypeid = (SELECT eventtypeid FROM eventtypes WHERE eventtypename = 'Type Name');
-- If count is 0, you can safely delete: DELETE FROM eventtypes WHERE eventtypename = 'Type Name';

-- ============================================
-- Insert Sample User (for testing)
-- ============================================
-- Default credentials: username='justmax', password='admin'
-- IMPORTANT: Change this password in production!
INSERT INTO users (username, password) VALUES
    ('justmax', 'admin');

-- ============================================
-- Insert Sample Events (optional - for testing)
-- ============================================
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventtypeid) VALUES
    (
        'Tech Career Fair',
        'Meet recruiters from top tech companies and explore internship opportunities.',
        '2025-11-05 10:00:00',
        '2025-11-05 15:00:00',
        'BYU Wilkinson Center',
        'BYU Career Services',
        1
    ),
    (
        'AIS Club Networking Night',
        'An evening of networking with IS alumni and local professionals.',
        '2025-11-07 18:00:00',
        '2025-11-07 20:00:00',
        'TNRB Atrium',
        'AIS Club',
        2
    ),
    (
        'Python Automation Workshop',
        'Hands-on workshop covering Python scripts for workflow automation.',
        '2025-11-10 14:00:00',
        '2025-11-10 16:00:00',
        'HFAC Lab 210',
        'CS Department',
        3
    ),
    (
        'Data Visualization Challenge',
        'Compete in teams to build dashboards and tell stories with data.',
        '2025-11-12 09:00:00',
        '2025-11-12 17:00:00',
        'TNRB 151',
        'IS Department',
        3
    ),
    (
        'IS Holiday Social',
        'Celebrate the semester with food, games, and holiday cheer.',
        '2025-12-01 19:00:00',
        '2025-12-01 22:00:00',
        'Provo Library Ballroom',
        'IS Student Association',
        4
    );

-- ============================================
-- Create Indexes for Better Performance
-- ============================================
CREATE INDEX idx_events_starttime ON events(starttime);
CREATE INDEX idx_events_eventtypeid ON events(eventtypeid);
CREATE INDEX idx_events_eventname ON events(eventname);

-- ============================================
-- Verify Tables and Data
-- ============================================
-- Uncomment the following queries to verify the setup:

-- View all event types:
-- SELECT * FROM eventtypes ORDER BY eventtypename;

-- View all events:
-- SELECT * FROM events;

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
--     et.eventtypename
-- FROM events e
-- LEFT JOIN eventtypes et ON e.eventtypeid = et.eventtypeid
-- ORDER BY e.starttime;

-- View event types with event counts:
-- SELECT 
--     et.eventtypeid,
--     et.eventtypename,
--     COUNT(e.eventid) as event_count
-- FROM eventtypes et
-- LEFT JOIN events e ON et.eventtypeid = e.eventtypeid
-- GROUP BY et.eventtypeid, et.eventtypename
-- ORDER BY et.eventtypename;

-- ============================================
-- Script Complete!
-- ============================================
-- You can now:
-- 1. Login with username: justmax, password: admin
-- 2. Create, read, update, and delete events
-- 3. View events on the public /events page
--
-- Remember to change the default password in production!

