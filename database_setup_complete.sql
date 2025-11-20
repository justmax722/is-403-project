DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS eventtypes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

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
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(50) NOT NULL
);

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

INSERT INTO users (username, password) VALUES ('justmax', 'admin');

