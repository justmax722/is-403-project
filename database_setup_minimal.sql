-- ============================================
-- Minimal Database Setup Script
-- Use this if you only want tables without sample data
-- ============================================

-- Drop tables if they exist (in reverse order due to foreign keys)
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS eventtypes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create EventTypes Table
CREATE TABLE eventtypes (
    eventtypeid SERIAL PRIMARY KEY,
    eventtypename VARCHAR(100) NOT NULL UNIQUE
);

-- Create Events Table
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

-- Create Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(50) NOT NULL
);

-- Create Indexes
CREATE INDEX idx_events_starttime ON events(starttime);
CREATE INDEX idx_events_eventtypeid ON events(eventtypeid);
CREATE INDEX idx_events_eventname ON events(eventname);

-- Insert event types (required for the app to work)
-- Using ON CONFLICT DO NOTHING to allow script to be run multiple times safely
INSERT INTO eventtypes (eventtypename) VALUES ('Career') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Networking') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Workshop') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Club Meetings') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Social') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Informational') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Other') ON CONFLICT (eventtypename) DO NOTHING;

-- Insert a test user (change password in production!)
-- Default credentials: username='justmax', password='admin'
INSERT INTO users (username, password) VALUES ('justmax', 'admin');

-- ============================================
-- Verify Setup
-- ============================================
-- Uncomment to verify the setup:
-- SELECT * FROM eventtypes ORDER BY eventtypename;
-- SELECT * FROM users;

