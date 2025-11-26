DROP TABLE IF EXISTS event_submissions CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS eventtypes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- NOTE: When migrating from the previous schema, copy any submitter rows into
-- the new `users` table (email/password pairs) with `role = 'S'` before running
-- this script so submitted events keep pointing at valid users.

CREATE TABLE eventtypes (
    eventtypeid SERIAL PRIMARY KEY,
    eventtypename VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE events (
    eventid SERIAL PRIMARY KEY,
    eventname VARCHAR(200) NOT NULL,
    eventdescription TEXT,
    starttime TIMESTAMP NOT NULL,
    endtime TIMESTAMP NOT NULL,
    eventlocation VARCHAR(200),
    eventhost VARCHAR(200),
    eventurl VARCHAR(500),
    eventlinktext VARCHAR(200),
    eventimagepath VARCHAR(500),
    eventtypeid INTEGER NOT NULL,
    CONSTRAINT fk_eventtype FOREIGN KEY (eventtypeid) 
        REFERENCES eventtypes(eventtypeid) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT chk_end_after_start CHECK (endtime > starttime)
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role CHAR(1) NOT NULL DEFAULT 'S',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_user_role CHECK (role IN ('A', 'S'))
);

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
    eventtypeid INTEGER NOT NULL REFERENCES eventtypes(eventtypeid) ON DELETE RESTRICT ON UPDATE CASCADE,
    submitterid INTEGER REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_submissions_status ON event_submissions(status);
CREATE INDEX idx_event_submissions_submitter ON event_submissions(submitterid);

CREATE INDEX idx_events_starttime ON events(starttime);
CREATE INDEX idx_events_eventtypeid ON events(eventtypeid);
CREATE INDEX idx_events_eventname ON events(eventname);

INSERT INTO eventtypes (eventtypename) VALUES ('Career') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Networking') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Workshop') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Club Meetings') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Social') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Informational') ON CONFLICT (eventtypename) DO NOTHING;
INSERT INTO eventtypes (eventtypename) VALUES ('Other') ON CONFLICT (eventtypename) DO NOTHING;

INSERT INTO users (email, password, role) VALUES ('jmaximum72@gmail.com', 'admin', 'A');

