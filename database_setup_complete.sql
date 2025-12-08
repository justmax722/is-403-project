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
    eventimagepath VARCHAR(500),
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

-- ======================================
-- Seed Example Events for 2025–2026
-- ======================================

-- Career (eventtypeid = 1)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('IS Career Night: Tech & Consulting', 'Meet recruiters from tech, consulting, and product firms hiring IS majors.', 
 '2025-09-09 18:00', '2025-09-09 20:00', 'TNRB W408', 'BYU Career Services', 'https://careers.byu.edu', 'Career Services Site', NULL, 1),
('Analytics & Data Science Recruiting Fair', 'Companies share analytics roles, data internships, and full-time opportunities.', 
 '2025-09-23 16:00', '2025-09-23 18:00', 'TNRB Main Atrium', 'IS Department', NULL, NULL, NULL, 1),
('Product Management in Tech: Employer Panel', 'PMs discuss roadmapping, user stories, and how IS students can break into PM.', 
 '2025-10-07 17:30', '2025-10-07 19:00', 'TNRB 151', 'IS Student Association', NULL, NULL, NULL, 1),
('Cybersecurity Career Night', 'Security analysts and engineers explain career paths, certifications, and day-to-day work.', 
 '2025-10-21 18:00', '2025-10-21 20:00', 'CTB 109', 'Cybersecurity Student Association', NULL, NULL, NULL, 1),
('Consulting Pathways for IS Majors', 'Learn how IS skills align with management and technology consulting roles.', 
 '2025-11-04 17:00', '2025-11-04 18:30', 'TNRB 171', 'BYU Management Consulting Association', NULL, NULL, NULL, 1),
('Internship Pitch Night', 'Students give 2-minute pitches to recruiters about their skills and projects.', 
 '2025-11-18 18:00', '2025-11-18 19:30', 'TNRB W408', 'IS Program', NULL, NULL, NULL, 1),
('Winter 2026 IS Career Prep Session', 'Overview of recruiting timelines, resume tips, and networking strategy for Winter semester.', 
 '2026-01-08 16:00', '2026-01-08 17:00', 'TNRB 270', 'IS Undergraduate Advisement', NULL, NULL, NULL, 1),
('Tech & Analytics Internship Night', 'Panel of students who completed IS-related internships share lessons learned.', 
 '2026-01-29 18:00', '2026-01-29 19:30', 'TNRB 283', 'IS Student Leadership', NULL, NULL, NULL, 1),
('Cloud Engineering Career Forum', 'Alumni working in cloud infrastructure and DevOps answer questions from students.', 
 '2026-02-19 17:00', '2026-02-19 18:30', 'TNRB 151', 'IS Department', NULL, NULL, NULL, 1),
('Spring 2026 Last-Minute Internship Meetup', 'Informal meetup to connect students with any remaining summer internship options.', 
 '2026-04-14 16:00', '2026-04-14 17:30', 'TNRB Atrium', 'BYU Career Services', NULL, NULL, NULL, 1),
('Summer 2026 Virtual Career Q&A', 'Online Q&A about off-cycle internships and remote tech roles.', 
 '2026-06-11 11:00', '2026-06-11 12:00', 'Online (Zoom)', 'IS Advisement Center', NULL, 'Join via Zoom', NULL, 1),
('Breaking into Data Product Roles', 'Hybrid roles at the intersection of data, engineering, and product for IS majors.', 
 '2026-07-09 17:00', '2026-07-09 18:30', 'TNRB 270', 'IS Alumni Board', NULL, NULL, NULL, 1);

-- Networking (eventtypeid = 2)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('IS Alumni Networking Mixer', 'Connect with IS alumni in analytics, security, and product across Utah County.', 
 '2025-09-19 19:00', '2025-09-19 20:30', 'Hinckley Alumni Center', 'IS Alumni Board', NULL, NULL, NULL, 2),
('Junior Core Cohort Networking Night', 'Meet students from other IS sections and form project and study groups.', 
 '2025-10-03 18:00', '2025-10-03 19:30', 'TNRB 270', 'IS Student Leadership', NULL, NULL, NULL, 2),
('Meet the Firms: IS Edition', 'Small group discussions with representatives from IS-focused employers.', 
 '2025-10-24 17:00', '2025-10-24 19:00', 'TNRB Atrium', 'BYU Marriott School', NULL, NULL, NULL, 2),
('Tech Women in IS Meetup', 'Networking event highlighting women leaders and students in IS.', 
 '2025-11-07 18:30', '2025-11-07 20:00', 'TNRB 283', 'WiSTEM & IS Dept', NULL, NULL, NULL, 2),
('First-Year IS Interest Social', 'Pre-major students mingle with current IS majors and ask questions.', 
 '2025-11-21 17:00', '2025-11-21 18:30', 'TNRB W408', 'IS Ambassadors', NULL, NULL, NULL, 2),
('New Year IS Networking Kickoff', 'Start Winter semester with intentional networking between classes and cohorts.', 
 '2026-01-10 18:00', '2026-01-10 19:00', 'TNRB 151', 'IS Student Association', NULL, NULL, NULL, 2),
('Analytics & BI Professionals Meetup', 'Industry professionals and students share tools and projects in business intelligence.', 
 '2026-01-31 17:30', '2026-01-31 19:00', 'TNRB 171', 'Analytics Club', NULL, NULL, NULL, 2),
('Startup & IS Networking Night', 'Meet founders and IS students interested in startups and entrepreneurship.', 
 '2026-02-21 19:00', '2026-02-21 20:30', 'TNRB Atrium', 'Rollins Center & IS Dept', NULL, NULL, NULL, 2),
('IS Mentorship Speed Networking', 'Speed networking format to connect mentees with IS upperclassman mentors.', 
 '2026-03-06 16:30', '2026-03-06 18:00', 'TNRB 270', 'IS Student Leadership', NULL, NULL, NULL, 2),
('Pre-Spring Term IS Connection Night', 'Meet students staying on campus for Spring IS classes and projects.', 
 '2026-04-24 17:00', '2026-04-24 18:00', 'TNRB W408', 'IS Department', NULL, NULL, NULL, 2),
('Summer IS Picnic & Networking', 'Casual outdoor picnic with alumni and students working in Utah for the summer.', 
 '2026-06-05 18:00', '2026-06-05 20:00', 'Kiwanis Park', 'IS Alumni Board', NULL, NULL, NULL, 2),
('IS Returners Networking Night', 'Networking for students returning from missions or internships and re-entering the program.', 
 '2026-07-24 18:00', '2026-07-24 19:30', 'TNRB 151', 'IS Advisement', NULL, NULL, NULL, 2);

-- Workshop (eventtypeid = 3)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('SQL Fundamentals Workshop', 'Hands-on introduction to SELECT, JOIN, and aggregate queries for IS students.', 
 '2025-09-11 16:00', '2025-09-11 18:00', 'TNRB 171', 'IS 201 TAs', NULL, NULL, NULL, 3),
('SQL Deep Dive: Performance & Indexing', 'Explore query plans, indexes, and performance tuning using real datasets.', 
 '2025-09-25 16:00', '2025-09-25 18:00', 'TNRB 283', 'IS 402 Faculty', NULL, NULL, NULL, 3),
('Intro to Tableau for IS Dashboards', 'Build your first interactive dashboard from a BYU dataset.', 
 '2025-10-02 17:00', '2025-10-02 19:00', 'TNRB 270', 'IS Analytics Club', NULL, NULL, NULL, 3),
('Building APIs with Node & Express', 'Create and test RESTful APIs used by IS 403-style applications.', 
 '2025-10-16 17:00', '2025-10-16 19:00', 'TNRB 171', 'IS 403 TAs', NULL, NULL, NULL, 3),
('Git & GitHub for Team Projects', 'Workshop on branching, pull requests, and resolving merge conflicts.', 
 '2025-11-06 16:00', '2025-11-06 18:00', 'TNRB 151', 'IS 415 TAs', NULL, NULL, NULL, 3),
('Intro to Cloud: AWS for IS Students', 'Launch basic services on AWS and connect them to simple IS projects.', 
 '2025-11-20 17:00', '2025-11-20 19:00', 'TNRB 283', 'Cloud Computing Club', NULL, NULL, NULL, 3),
('Winter 2026 Resume & LinkedIn Workshop', 'Optimize IS-focused resumes and LinkedIn profiles.', 
 '2026-01-15 16:00', '2026-01-15 17:30', 'TNRB 270', 'Career Services & IS Dept', NULL, NULL, NULL, 3),
('Python for Data Analytics Bootcamp', 'Hands-on intro to pandas, visualization, and basic data cleaning.', 
 '2026-01-27 17:00', '2026-01-27 19:00', 'TNRB 171', 'Analytics Club', NULL, NULL, NULL, 3),
('UX Design for IS Projects', 'Learn basics of wireframing, prototyping, and usability testing for IS apps.', 
 '2026-02-17 17:00', '2026-02-17 19:00', 'TNRB 151', 'UX Club & IS Dept', NULL, NULL, NULL, 3),
('Cybersecurity Hands-On Lab Night', 'Practice basic security testing and hardening in a guided lab.', 
 '2026-03-03 18:00', '2026-03-03 20:00', 'CTB Security Lab', 'Cybersecurity Student Association', NULL, NULL, NULL, 3),
('Spring 2026 IS Project Kickoff Workshop', 'Workshop for students building personal or class IS projects during Spring term.', 
 '2026-05-07 16:00', '2026-05-07 18:00', 'TNRB 283', 'IS Faculty', NULL, NULL, NULL, 3),
('Automation with Power BI and Power Apps', 'Low-code automation tools for business workflows relevant to IS.', 
 '2026-06-18 17:00', '2026-06-18 19:00', 'TNRB 171', 'IS Department', NULL, NULL, NULL, 3);

-- Club Meetings (eventtypeid = 4)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('AIS Chapter Kickoff Fall 2025', 'First meeting of the semester with an overview of AIS activities and leadership.', 
 '2025-09-03 12:00', '2025-09-03 13:00', 'TNRB W408', 'Association for Information Systems', NULL, NULL, NULL, 4),
('Cybersecurity Club Welcome Meeting', 'Intro to club activities, competitions, and security projects for Fall 2025.', 
 '2025-09-10 12:00', '2025-09-10 13:00', 'CTB 109', 'Cybersecurity Student Association', NULL, NULL, NULL, 4),
('Analytics Club Monthly Meeting', 'Discussion of upcoming analytics competitions and trainings.', 
 '2025-09-17 12:00', '2025-09-17 13:00', 'TNRB 151', 'Analytics Club', NULL, NULL, NULL, 4),
('AIS Case Competition Info Meeting', 'Details about the upcoming IS case competition and how to form teams.', 
 '2025-10-01 12:00', '2025-10-01 13:00', 'TNRB 270', 'AIS', NULL, NULL, NULL, 4),
('Cybersecurity CTF Practice Session', 'Team practice for upcoming capture-the-flag cyber competitions.', 
 '2025-10-15 18:00', '2025-10-15 20:00', 'CTB Lab', 'Cybersecurity Student Association', NULL, NULL, NULL, 4),
('Analytics Club Competition Kickoff', 'Kickoff for a semester-long analytics challenge with real data.', 
 '2025-10-29 17:00', '2025-10-29 18:30', 'TNRB 283', 'Analytics Club', NULL, NULL, NULL, 4),
('AIS Mid-Semester Check-In', 'Updates on club projects, committees, and service opportunities.', 
 '2025-11-12 12:00', '2025-11-12 13:00', 'TNRB 171', 'AIS', NULL, NULL, NULL, 4),
('IS Social Impact Tech Group Meeting', 'Discuss using IS skills to support social impact and nonprofit projects.', 
 '2025-11-19 17:00', '2025-11-19 18:00', 'TNRB 151', 'IS Social Impact Group', NULL, NULL, NULL, 4),
('Winter 2026 AIS Kickoff', 'Welcome back meeting for AIS with Winter semester plans.', 
 '2026-01-08 12:00', '2026-01-08 13:00', 'TNRB W408', 'AIS', NULL, NULL, NULL, 4),
('Cybersecurity Club Winter Strategy Meeting', 'Plan Winter semester labs, speakers, and competitions.', 
 '2026-01-22 12:00', '2026-01-22 13:00', 'CTB 109', 'Cybersecurity Student Association', NULL, NULL, NULL, 4),
('Analytics Club Guest Speaker Lunch', 'Industry guest shares how they use analytics in their role.', 
 '2026-02-19 12:00', '2026-02-19 13:00', 'TNRB 270', 'Analytics Club', NULL, NULL, NULL, 4),
('AIS End-of-Year Celebration Meeting', 'Final AIS meeting to celebrate accomplishments and transition leadership.', 
 '2026-04-08 12:00', '2026-04-08 13:00', 'TNRB 171', 'AIS', NULL, NULL, NULL, 4);

-- Social (eventtypeid = 5)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('IS Program Fall Social', 'Kickoff social with food, games, and an intro to IS faculty and staff.', 
 '2025-09-06 18:00', '2025-09-06 20:00', 'Helaman Fields Pavilion', 'IS Student Leadership', NULL, NULL, NULL, 5),
('IS Game Night', 'Board games, card games, and snacks with other IS majors.', 
 '2025-09-26 19:00', '2025-09-26 21:00', 'TNRB W408', 'IS Student Association', NULL, NULL, NULL, 5),
('IS Movie & Pizza Night', 'Relax with classmates and enjoy a tech-themed movie.', 
 '2025-10-17 19:30', '2025-10-17 22:00', 'TNRB 151', 'IS Student Association', NULL, NULL, NULL, 5),
('Junior Core Friendsgiving Social', 'Thanksgiving-themed potluck social for Junior Core cohorts.', 
 '2025-11-14 18:00', '2025-11-14 20:00', 'TNRB Atrium', 'IS Student Leadership', NULL, NULL, NULL, 5),
('Late-Night Coding & Cocoa Social', 'Work on projects or homework with hot chocolate and music.', 
 '2025-12-05 20:00', '2025-12-05 23:00', 'TNRB 283', 'IS TAs & Student Association', NULL, NULL, NULL, 5),
('Winter 2026 Welcome Back Social', 'Casual get-together to reconnect after the break.', 
 '2026-01-09 18:00', '2026-01-09 20:00', 'Wilkinson Center Lounge', 'IS Department', NULL, NULL, NULL, 5),
('IS Valentines Treat Bar', 'Drop-in event with treats and a chance to meet new people in the program.', 
 '2026-02-13 12:00', '2026-02-13 14:00', 'TNRB Atrium', 'IS Student Association', NULL, NULL, NULL, 5),
('IS March Madness Watch Party', 'Watch March Madness games and hang out with IS cohorts.', 
 '2026-03-19 17:00', '2026-03-19 21:00', 'TNRB W408', 'IS Student Leadership', NULL, NULL, NULL, 5),
('End-of-Winter IS Bash', 'Celebrate the end of Winter semester with food and games.', 
 '2026-04-10 18:00', '2026-04-10 20:00', 'Kiwanis Park', 'IS Department', NULL, NULL, NULL, 5),
('Spring 2026 Outdoor Social', 'Outdoor games and snacks for IS students taking Spring classes.', 
 '2026-05-15 18:00', '2026-05-15 20:00', 'Provo Canyon Park', 'IS Student Association', NULL, NULL, NULL, 5),
('Summer 2026 Ice Cream Social', 'Cool off with ice cream and connect with IS students on campus.', 
 '2026-06-26 18:00', '2026-06-26 19:30', 'TNRB Atrium', 'IS Department', NULL, NULL, NULL, 5),
('Pre-Fall 2026 IS Welcome BBQ', 'Barbecue-style social to welcome new and returning IS students.', 
 '2026-07-31 18:00', '2026-07-31 20:00', 'Helaman Fields Pavilion', 'IS Student Leadership', NULL, NULL, NULL, 5);

-- Informational (eventtypeid = 6)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('IS Major Overview Night', 'High-level overview of the IS major, classes, and career outcomes.', 
 '2025-09-04 17:00', '2025-09-04 18:00', 'TNRB 270', 'IS Undergraduate Advisement', NULL, NULL, NULL, 6),
('Junior Core Application Info Session', 'Walkthrough of requirements, timeline, and tips for applying to the Junior Core.', 
 '2025-09-18 17:00', '2025-09-18 18:00', 'TNRB 151', 'IS Advisement Center', NULL, NULL, NULL, 6),
('IS Emphasis & Track Options', 'Learn about security, analytics, development, and other IS emphasis options.', 
 '2025-10-09 16:00', '2025-10-09 17:00', 'TNRB 171', 'IS Department', NULL, NULL, NULL, 6),
('Study Abroad & IS Global Opportunities', 'Overview of study abroad and global consulting programs for IS students.', 
 '2025-10-30 16:00', '2025-10-30 17:00', 'TNRB 270', 'Global Management Center', NULL, NULL, NULL, 6),
('Pre-MIS Grad School Info Night', 'Information on Master of Information Systems and related graduate programs.', 
 '2025-11-13 17:00', '2025-11-13 18:00', 'TNRB 283', 'IS Graduate Program', NULL, NULL, NULL, 6),
('IS Scholarship Information Session', 'Details on scholarships available to IS students and how to apply.', 
 '2025-11-20 16:00', '2025-11-20 17:00', 'TNRB 151', 'IS Department', NULL, NULL, NULL, 6),
('Winter 2026 IS Degree Planning Session', 'Degree planning help for pre-IS and current IS majors.', 
 '2026-01-16 13:00', '2026-01-16 14:00', 'TNRB 171', 'IS Advisement Center', NULL, NULL, NULL, 6),
('Internship Credit & Registration Q&A', 'How to register IS internships for credit and meet requirements.', 
 '2026-02-06 12:00', '2026-02-06 13:00', 'TNRB 270', 'IS Internship Coordinator', NULL, NULL, NULL, 6),
('Capstone & Project Course Overview', 'Information on capstone-style projects and how to prepare.', 
 '2026-03-13 16:00', '2026-03-13 17:00', 'TNRB 283', 'IS Faculty', NULL, NULL, NULL, 6),
('Spring 2026 New IS Student Orientation', 'Orientation session for students entering IS classes in Spring term.', 
 '2026-04-30 15:00', '2026-04-30 16:00', 'TNRB 151', 'IS Department', NULL, NULL, NULL, 6),
('Online & Remote IS Opportunities Info Session', 'Discuss fully remote classes, internships, and projects for IS majors.', 
 '2026-06-04 11:00', '2026-06-04 12:00', 'Online (Zoom)', 'IS Advisement', NULL, 'Join Online', NULL, 6),
('IS Alumni Pathways Spotlight', 'Informational panel where alumni explain how their IS degree shaped their careers.', 
 '2026-07-10 16:00', '2026-07-10 17:00', 'TNRB 270', 'IS Alumni Board', NULL, NULL, NULL, 6);

-- Other (eventtypeid = 7)
INSERT INTO events (eventname, eventdescription, starttime, endtime, eventlocation, eventhost, eventurl, eventlinktext, eventimagepath, eventtypeid)
VALUES
('IS Research Lab Open House', 'Tour research labs and learn how to assist professors on IS research projects.', 
 '2025-09-30 14:00', '2025-09-30 16:00', 'TNRB 490', 'IS Research Lab', NULL, NULL, NULL, 7),
('Hackathon Info & Team Formation Night', 'Form teams and learn rules for an upcoming IS-themed hackathon.', 
 '2025-10-08 18:00', '2025-10-08 19:30', 'TNRB 283', 'IS Student Association', NULL, NULL, NULL, 7),
('Mini Hackathon: BYU Data Challenge', 'Short-format hackathon using BYU data to solve real problems.', 
 '2025-11-01 09:00', '2025-11-01 13:00', 'TNRB 171', 'Analytics Club & IS Dept', NULL, NULL, NULL, 7),
('Service Project: Tech Help for Nonprofits', 'IS students volunteer to assist local nonprofits with tech needs.', 
 '2025-11-22 09:00', '2025-11-22 12:00', 'Off-Campus Nonprofit Sites', 'IS Social Impact Group', NULL, NULL, NULL, 7),
('Finals Week Study Marathon', 'Quiet space and snacks for IS students studying for finals.', 
 '2025-12-10 18:00', '2025-12-10 23:00', 'TNRB 270', 'IS Student Leadership', NULL, NULL, NULL, 7),
('Winter 2026 Hack Night', 'Open lab time to work on side projects with help from TAs and peers.', 
 '2026-01-30 18:00', '2026-01-30 22:00', 'TNRB 283', 'IS 403 & 404 TAs', NULL, NULL, NULL, 7),
('IS Spiritual Thought & Devotional', 'Short devotional tailored to IS students, followed by refreshments.', 
 '2026-02-27 11:00', '2026-02-27 12:00', 'TNRB 151', 'IS Department', NULL, NULL, NULL, 7),
('Innovation Sprint: Process Improvement', 'Intensive session to brainstorm and prototype process improvements on campus.', 
 '2026-03-20 13:00', '2026-03-20 17:00', 'TNRB 171', 'IS Department & Partners', NULL, NULL, NULL, 7),
('IS Poster Session & Project Showcase', 'Students present IS projects to peers, faculty, and guests.', 
 '2026-04-03 15:00', '2026-04-03 17:00', 'TNRB Atrium', 'IS Program', NULL, NULL, NULL, 7),
('Spring 2026 Tech Service Day', 'Group service project focused on helping community members with basic tech skills.', 
 '2026-05-23 09:00', '2026-05-23 12:00', 'Provo Library', 'IS Social Impact Group', NULL, NULL, NULL, 7),
('IS Innovation Expo Planning Meeting', 'Core planning meeting for a future IS innovation expo event.', 
 '2026-06-12 14:00', '2026-06-12 15:30', 'TNRB 270', 'IS Student Leadership', NULL, NULL, NULL, 7),
('Summer 2026 IS Project Demo Day', 'Informal showcase of personal and internship projects built by IS students.', 
 '2026-07-17 15:00', '2026-07-17 17:00', 'TNRB 283', 'IS Department', NULL, NULL, NULL, 7);
