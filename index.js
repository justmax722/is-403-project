//npm install dotenv - explain
//npm install express-session - explain
//create the .env file

// Load environment variables from .env file into memory
// Allows you to use process.env
require('dotenv').config();

const express = require("express");

//Needed for the session variable - Stored on the server to hold data
const session = require("express-session");

// Note: Image upload functionality has been removed

const formatDateTimeLocal = (datetimeLocal) => {
    if (!datetimeLocal) return null;
    return datetimeLocal.replace('T', ' ') + ':00';
};

// Note: `path` and `body-parser` are not required for this minimal assignment; removed to simplify

let app = express();

// Use EJS for the web pages - requires a views folder and all files are .ejs
app.set("view engine", "ejs");

// process.env.PORT is when you deploy and 3000 is for test
const port = process.env.PORT || 3000;

/* Session middleware (Middleware is code that runs between the time the request comes
to the server and the time the response is sent back. It allows you to intercept and
decide if the request should continue. It also allows you to parse the body request
from the html form, handle errors, check authentication, etc.)

REQUIRED parameters for session:
secret - The only truly required parameter
    Used to sign session cookies
    Prevents tampering and session hijacking with session data

OPTIONAL (with defaults):
resave - Default: true
    true = save session on every request
    false = only save if modified (recommended)

saveUninitialized - Default: true
    true = create session for every request
    false = only create when data is stored (recommended)
*/

app.use(
    session(
        {
    secret: process.env.SESSION_SECRET || 'fallback-secret-key',
    resave: false,
    saveUninitialized: false,
        }
    )
);

// Database connection - supports both DB_* and PG* environment variables (PostgreSQL standard)
// Prioritizes PG* variables (standard for PostgreSQL) and falls back to DB_* for backward compatibility
const dbHost = process.env.PGHOST || process.env.DB_HOST || "localhost";
const isLocalhost = dbHost === "localhost" || dbHost === "127.0.0.1";

// Default port: 5433 for localhost, can be overridden by environment variables for AWS
const dbPort = process.env.PGPORT || process.env.DB_PORT;
const defaultPort = isLocalhost ? 5433 : 5432; // 5433 for local pgAdmin, 5432 for standard PostgreSQL

// Get database credentials from environment variables or use defaults
const dbUser = process.env.PGUSER || process.env.DB_USER || "postgres";
const dbPassword = process.env.PGPASSWORD || process.env.DB_PASSWORD || "admin";
const dbName = process.env.PGDATABASE || process.env.DB_NAME || "project3";
const finalPort = parseInt(dbPort || defaultPort);

// Log connection info for debugging (without password)
console.log("Database connection config:");
console.log(`  Host: ${dbHost}`);
console.log(`  Port: ${finalPort}`);
console.log(`  User: ${dbUser}`);
console.log(`  Database: ${dbName}`);
console.log(`  SSL: ${!isLocalhost ? 'enabled' : 'disabled'}`);

const knex = require("knex")({
    client: "pg",
    connection: {
        host: dbHost,
        user: dbUser,
        password: dbPassword,
        database: dbName,
        port: finalPort,
        // SSL configuration for AWS RDS (required for secure connections)
        // Enable SSL for remote connections (RDS), disable for localhost
        ssl: !isLocalhost ? {
            rejectUnauthorized: false  // Required for AWS RDS - certificates are self-signed but connection is still encrypted
        } : false
    }
});

// Tells Express how to read form data sent in the body of a request
app.use(express.urlencoded({extended: true}));

// Note: Image upload directory creation removed - images no longer supported

// Serve static files from public directory (for CSS, images, etc.)
// This must come BEFORE authentication middleware so CSS/images load without login
app.use(express.static("public"));

// Global authentication middleware - runs on EVERY request
// Note: Static files are served by express.static above, so CSS/images load without auth
// If a static file doesn't exist, express.static calls next() and the request continues here
app.use((req, res, next) => {
    const publicRoutes = ['/', '/login', '/logout', '/events', '/signup', '/submit-event'];
    if (publicRoutes.includes(req.path)) {
        return next();
    }

    const isSubmitterRoute = req.path.startsWith("/submitter");
    if (isSubmitterRoute && req.session.userRole === "submitter" && req.session.submitterId) {
        return next();
    }

    if (req.session.isLoggedIn) {
        return next();
    }

    renderLoginView(res, { loginError: "Please log in to access this page" });
});

const renderLoginView = (res, { loginError = '', signupError = '', activeForm = 'login' } = {}) => {
    res.render("login", {
        error_message: loginError,
        signup_error_message: signupError,
        activeForm
    });
};

const handleEventsPage = (req, res) => {
    const startDate = req.query.startDate;
    const endDate = req.query.endDate;
    const categories = req.query.categories ? (Array.isArray(req.query.categories) ? req.query.categories : [req.query.categories]) : [];
    const format = req.query.format || 'grid';
    const searchTerm = req.query.search ? req.query.search.trim() : '';
    const sortDirection = req.query.sort === 'desc' ? 'desc' : 'asc';
    const userRole = req.session.userRole || '';

    const eventTypesQuery = knex.select("eventtypeid", "eventtypename")
        .from("eventtypes")
        .orderBy("eventtypename", "asc");

    let eventsQuery = knex.select(
        "events.eventid",
        "events.eventname",
        "events.eventdescription",
        "events.starttime",
        "events.endtime",
        "events.eventlocation",
        "events.eventhost",
        "events.eventurl",
        "events.eventlinktext",
        "events.eventtypeid",
        "eventtypes.eventtypename"
    )
    .from("events")
    .leftJoin("eventtypes", "events.eventtypeid", "eventtypes.eventtypeid")
    .where("events.endtime", ">", knex.fn.now());

    if (startDate && endDate) {
        eventsQuery = eventsQuery.where("events.starttime", "<=", endDate + " 23:59:59")
                                  .where("events.endtime", ">=", startDate + " 00:00:00");
    } else if (startDate) {
        eventsQuery = eventsQuery.where("events.endtime", ">=", startDate + " 00:00:00");
    } else if (endDate) {
        eventsQuery = eventsQuery.where("events.starttime", "<=", endDate + " 23:59:59");
    }

    if (categories.length > 0) {
        eventsQuery = eventsQuery.whereIn("events.eventtypeid", categories.map(id => parseInt(id)));
    }

    if (searchTerm) {
        const searchPattern = `%${searchTerm}%`;
        eventsQuery = eventsQuery.where(function() {
            this.where("events.eventname", "ilike", searchPattern)
                .orWhere("events.eventdescription", "ilike", searchPattern);
        });
    }

    eventsQuery = eventsQuery.orderBy("events.starttime", sortDirection);

    Promise.all([eventTypesQuery, eventsQuery])
        .then(([eventTypes, events]) => {
            res.render("events", { 
                events: events || [], 
                eventTypes: eventTypes || [],
                currentFilters: {
                    startDate: startDate || '',
                    endDate: endDate || '',
                    categories: categories,
                    format: format,
                    search: searchTerm,
                    sort: sortDirection
                },
                isLoggedIn: req.session.isLoggedIn || false,
                currentUrl: req.originalUrl,
                userRole
            });
        })
        .catch(err => {
            console.error("Failed to load events:", err);
            res.render("events", { 
                events: [], 
                eventTypes: [],
                currentFilters: {
                    startDate: '',
                    endDate: '',
                    categories: [],
                    format: format,
                    search: searchTerm,
                    sort: sortDirection
                },
                error_message: "Failed to load events.",
                isLoggedIn: req.session.isLoggedIn || false,
                currentUrl: req.originalUrl,
                userRole
            });
        });
};

app.get("/", handleEventsPage);
app.get("/login", (req, res) => {
    renderLoginView(res);
});

app.get("/events", handleEventsPage);

// This creates attributes in the session object to keep track of user and if they logged in
app.post("/login", async (req, res) => {
    const emailInput = req.body.email ? req.body.email.trim().toLowerCase() : '';
    const password = req.body.password;

    if (!emailInput || !password) {
        return renderLoginView(res, {
            loginError: "Please enter both email and password.",
            activeForm: "login"
        });
    }

    try {
        const adminUser = await knex("users")
            .select("id", "email")
            .where({
                role: 'A',
                email: emailInput,
                password
            })
            .first();

        if (adminUser) {
            req.session.isLoggedIn = true;
            req.session.userEmail = adminUser.email;
            req.session.userRole = "admin";
            return res.redirect("/admin/dashboard");
        }

        const submitter = await knex("users")
            .select("id", "email")
            .where({
                role: 'S',
                email: emailInput,
                password
            })
            .first();

        if (submitter) {
            req.session.isLoggedIn = true;
            req.session.submitterId = submitter.id;
            req.session.submitterEmail = submitter.email;
            req.session.userRole = "submitter";
            return res.redirect("/submitter/dashboard");
        }

        renderLoginView(res, {
            loginError: "Invalid login",
            activeForm: "login"
        });
    } catch (err) {
        console.error("Login error:", err);
        renderLoginView(res, {
            loginError: "Invalid login",
            activeForm: "login"
        });
    }
});

// Logout route
app.get("/logout", (req, res) => {
    const requestedReturn = typeof req.query.next === 'string' ? req.query.next : '';
    const redirectTarget = requestedReturn.startsWith('/') ? requestedReturn : '/';
    req.session.destroy((err) => {
        if (err) {
            console.log(err);
        }
        res.redirect(redirectTarget);
    });
});

app.get("/signup", (req, res) => {
    renderLoginView(res, { activeForm: "signup" });
});

app.post("/signup", async (req, res) => {
    const email = req.body.email ? req.body.email.trim().toLowerCase() : '';
    const password = req.body.password;
    const confirmPassword = req.body.confirmPassword;

    if (!email || !password || !confirmPassword) {
        return renderLoginView(res, {
            signupError: "All fields are required.",
            activeForm: "signup"
        });
    }

    if (password !== confirmPassword) {
        return renderLoginView(res, {
            signupError: "Passwords do not match.",
            activeForm: "signup"
        });
    }

    try {
        const existing = await knex("users")
            .where("email", email)
            .first();

        if (existing) {
            throw new Error("That email is already registered.");
        }

        const insertedRows = await knex("users")
            .insert({
                email: email,
                password: password,
                role: 'S'
            })
            .returning("id");

        const newUser = insertedRows[0];

        if (!newUser || typeof newUser.id === 'undefined') {
            throw new Error("Unable to create account.");
        }

        req.session.isLoggedIn = true;
        req.session.submitterId = newUser.id;
        req.session.submitterEmail = email;
        req.session.userRole = "submitter";
        res.redirect("/submit-event");
    } catch (err) {
        console.error("Signup error:", err.message || err);
        renderLoginView(res, {
            signupError: err.message || "Unable to create account.",
            activeForm: "signup"
        });
    }
});

const loadSubmitEventData = (submitterId) => {
    const eventTypesPromise = knex.select("eventtypeid", "eventtypename")
        .from("eventtypes")
        .orderBy("eventtypename", "asc");

    const submissionsPromise = knex.select(
        "submissionid",
        "eventname",
        "status",
        "created_at",
        "starttime",
        "endtime",
        "eventtypeid"
    )
    .from("event_submissions")
    .where("submitterid", submitterId)
    .orderBy("created_at", "desc");

    return Promise.all([eventTypesPromise, submissionsPromise]);
};

const renderSubmitEvent = (req, res, { success_message = '', error_message = '', formData = {} } = {}) => {
    if (!req.session.submitterId) {
        return res.redirect("/signup");
    }

    const userRoleValue = req.session.userRole || '';
    loadSubmitEventData(req.session.submitterId)
        .then(([eventTypes, submissions]) => {
            res.render("submitEvent", {
                eventTypes: eventTypes || [],
                submissions: submissions || [],
                success_message,
                error_message,
                formData,
                userRole: userRoleValue
            });
        })
        .catch(err => {
            console.error("Failed to load submit-event data:", err);
            res.render("submitEvent", {
                eventTypes: [],
                submissions: [],
                success_message: '',
                error_message: "Unable to load event types. Please try again later.",
                formData,
                userRole: userRoleValue
            });
        });
};

app.get("/submit-event", (req, res) => {
    if (!req.session.submitterId) {
        return res.redirect("/signup");
    }

    const successMessage = req.query.success ? "Thanks! We'll review your submission shortly." : '';
    renderSubmitEvent(req, res, { success_message: successMessage });
});

app.post("/submit-event", (req, res) => {
    if (!req.session.submitterId) {
        return res.redirect("/signup");
    }

    const {
        eventName,
        eventDescription,
        startTime,
        endTime,
        eventLocation,
        eventHost,
        eventTypeID,
        eventURL,
        eventLinkText
    } = req.body;

    const formattedStart = formatDateTimeLocal(startTime);
    const formattedEnd = formatDateTimeLocal(endTime);

    const cleanedLocation = eventLocation ? eventLocation.trim() : '';

    const preservedFormData = {
        eventName: eventName ? eventName.trim() : '',
        eventDescription: eventDescription ? eventDescription.trim() : '',
        startTime,
        endTime,
        eventLocation: cleanedLocation,
        eventHost: eventHost ? eventHost.trim() : '',
        eventTypeID,
        eventURL: eventURL ? eventURL.trim() : '',
        eventLinkText: eventLinkText ? eventLinkText.trim() : ''
    };

    const renderWithError = (message) => {
        renderSubmitEvent(req, res, {
            error_message: message,
            formData: preservedFormData
        });
    };
    
    // Better validation with specific field checks
    const missingFields = [];
    if (!eventName || !eventName.trim()) missingFields.push('Event Name');
    if (!startTime || !formattedStart) missingFields.push('Start Time');
    if (!endTime || !formattedEnd) missingFields.push('End Time');
    if (!eventLocation || !cleanedLocation) missingFields.push('Location');
    if (!eventTypeID) missingFields.push('Event Type');
    
    if (missingFields.length > 0) {
        return renderWithError(`Please fill in all required fields: ${missingFields.join(', ')}`);
    }

    if (new Date(formattedEnd) <= new Date(formattedStart)) {
        return renderWithError("End time must be after start time.");
    }

    const submissionData = {
        eventname: eventName.trim(),
        eventdescription: eventDescription.trim(),
        starttime: formattedStart,
        endtime: formattedEnd,
        eventlocation: cleanedLocation,
        eventhost: eventHost ? eventHost.trim() : null,
        eventurl: eventURL ? eventURL.trim() : null,
        eventlinktext: eventLinkText ? eventLinkText.trim() : null,
        eventtypeid: parseInt(eventTypeID, 10),
        submitterid: req.session.submitterId,
        status: 'pending'
    };

    knex("event_submissions")
        .insert(submissionData)
        .then(() => {
            res.redirect("/submitter/dashboard?success=1");
        })
        .catch(err => {
            console.error("Failed to save submission:", err);
            renderWithError("Unable to submit your event. Please try again later.");
        });
});

app.get("/submitter/dashboard", (req, res) => {
    if (!req.session.submitterId) {
        return res.redirect("/login");
    }

    loadSubmitEventData(req.session.submitterId)
        .then(([, submissions]) => {
            res.render("submitterDashboard", {
                submissions: submissions || [],
                submitterEmail: req.session.submitterEmail || '',
                success_message: req.query.success ? "Thanks! We'll review your submission shortly." : '',
                error_message: ''
            });
        })
        .catch(err => {
            console.error("Failed to load submitter dashboard:", err);
            res.render("submitterDashboard", {
                submissions: [],
                submitterEmail: req.session.submitterEmail || '',
                error_message: "Unable to load your submissions right now.",
                success_message: ''
            });
        });
});

// ============================================
// ADMIN ROUTES - All require authentication
// ============================================

// Middleware to ensure only admins can access admin routes
const requireAdmin = (req, res, next) => {
    if (req.session.userRole === "admin") {
        return next();
    }
    
    // If user is a submitter, redirect to their dashboard
    if (req.session.userRole === "submitter" && req.session.submitterId) {
        return res.redirect("/submitter/dashboard");
    }
    
    // Otherwise, redirect to login
    return res.redirect("/login");
};

// Admin Dashboard - List all events (separate upcoming and past)
app.get("/admin/dashboard", requireAdmin, (req, res) => {
    const eventsQuery = knex.select(
        "events.eventid",
        "events.eventname",
        "events.starttime",
        "events.endtime",
        "events.eventlocation",
        "events.eventhost",
        "events.eventurl",
        "events.eventlinktext",
        "eventtypes.eventtypename as typename"
    )
    .from("events")
    .leftJoin("eventtypes", "events.eventtypeid", "eventtypes.eventtypeid")
    .orderBy("events.starttime", "asc");

    const submissionColumns = [
        "event_submissions.submissionid",
        "event_submissions.eventname",
        "event_submissions.starttime",
        "event_submissions.endtime",
        "event_submissions.eventlocation",
        "event_submissions.eventhost",
        "event_submissions.eventurl",
        "event_submissions.eventlinktext",
        "event_submissions.status",
        "event_submissions.created_at",
        "eventtypes.eventtypename as typename",
        "users.email as submitterEmail"
    ];

    const pendingSubmissionsQuery = knex("event_submissions")
        .select(submissionColumns)
        .leftJoin("eventtypes", "event_submissions.eventtypeid", "eventtypes.eventtypeid")
        .leftJoin("users", "event_submissions.submitterid", "users.id")
        .where("event_submissions.status", "pending")
        .orderBy("event_submissions.created_at", "asc");

    const deniedSubmissionsQuery = knex("event_submissions")
        .select(submissionColumns)
        .leftJoin("eventtypes", "event_submissions.eventtypeid", "eventtypes.eventtypeid")
        .leftJoin("users", "event_submissions.submitterid", "users.id")
        .where("event_submissions.status", "denied")
        .orderBy("event_submissions.created_at", "desc");

    Promise.all([eventsQuery, pendingSubmissionsQuery, deniedSubmissionsQuery])
        .then(([events, pendingSubmissions, deniedSubmissions]) => {
            const allEvents = events || [];
            const now = new Date();
            const pendingCount = (pendingSubmissions || []).length;

            const upcomingEvents = allEvents.filter(event => {
                if (!event.endtime) return false;
                return new Date(event.endtime) > now;
            });

            const pastEvents = allEvents.filter(event => {
                if (!event.endtime) return false;
                return new Date(event.endtime) <= now;
            });

            res.render("adminDashboard", {
                upcomingEvents: upcomingEvents,
                pastEvents: pastEvents,
                pendingSubmissions: pendingSubmissions || [],
                deniedSubmissions: deniedSubmissions || [],
                pendingCount
            });
        })
        .catch(err => {
            console.error("Failed to load events or submissions:", err);
            res.render("adminDashboard", {
                upcomingEvents: [],
                pastEvents: [],
                pendingSubmissions: [],
                deniedSubmissions: [],
                error_message: "Database error loading events."
            });
        });
});

app.post("/admin/submissions/:id/approve", requireAdmin, (req, res) => {
    const submissionId = parseInt(req.params.id, 10);
    if (isNaN(submissionId)) {
        return res.redirect("/admin/dashboard");
    }

    knex("event_submissions")
        .where("submissionid", submissionId)
        .first()
        .then(submission => {
            if (!submission || submission.status !== 'pending') {
                throw new Error("Submission not available for approval.");
            }

            const eventData = {
                eventname: submission.eventname,
                eventdescription: submission.eventdescription,
                starttime: submission.starttime,
                endtime: submission.endtime,
                eventlocation: submission.eventlocation,
                eventhost: submission.eventhost,
                eventurl: submission.eventurl,
                eventlinktext: submission.eventlinktext,
                eventtypeid: submission.eventtypeid
            };

            return knex("events")
                .insert(eventData);
        })
        .then(() => {
            return knex("event_submissions")
                .where("submissionid", submissionId)
                .update({ status: 'approved' });
        })
        .then(() => {
            res.redirect("/admin/dashboard");
        })
        .catch(err => {
            console.error("Approve submission error:", err);
            res.redirect("/admin/dashboard");
        });
});

app.post("/admin/submissions/:id/deny", requireAdmin, (req, res) => {
    const submissionId = parseInt(req.params.id, 10);
    if (isNaN(submissionId)) {
        return res.redirect("/admin/dashboard");
    }

    knex("event_submissions")
        .where("submissionid", submissionId)
        .update({ status: 'denied' })
        .then(() => {
            res.redirect("/admin/dashboard");
        })
        .catch(err => {
            console.error("Deny submission error:", err);
            res.redirect("/admin/dashboard");
        });
});

// Admin Create Event - Show form
app.get("/admin/create", requireAdmin, (req, res) => {
    // Get event types for dropdown
    knex.select("eventtypeid", "eventtypename")
        .from("eventtypes")
        .orderBy("eventtypename", "asc")
        .then(eventTypes => {
            // Ensure eventTypes is always an array
            res.render("adminCreate", { eventTypes: eventTypes || [], formData: {} });
        })
        .catch(err => {
            console.error("Failed to load event types:", err);
            res.render("adminCreate", { eventTypes: [], error_message: "Database error loading event types.", formData: {} });
        });
});

// Admin Create Event - Handle form submission with file upload
app.post("/admin/create", requireAdmin, (req, res) => {
    const { eventName, eventDescription, startTime, endTime, eventLocation, eventHost, eventTypeID, eventurl, eventlinktext } = req.body;
    const locationValue = eventLocation ? eventLocation.trim() : '';
    
    const formData = {
        eventName: eventName ? eventName.trim() : '',
        eventDescription: eventDescription ? eventDescription.trim() : '',
        startTime,
        endTime,
        eventLocation: locationValue,
        eventHost: eventHost ? eventHost.trim() : '',
        eventTypeID,
        eventurl: eventurl ? eventurl.trim() : '',
        eventlinktext: eventlinktext ? eventlinktext.trim() : ''
    };

    // Basic validation
    if (!eventName || !startTime || !endTime || !eventTypeID || !locationValue) {
        return knex.select("eventtypeid", "eventtypename")
            .from("eventtypes")
            .then(eventTypes => {
                res.render("adminCreate", { 
                    eventTypes: eventTypes || [], 
                    error_message: "Please fill in all required fields (Event Name, Start Time, End Time, Location, Event Type).",
                    formData
                });
            })
            .catch(() => {
                res.redirect("/admin/dashboard");
            });
    }
    
    // Convert datetime-local format (YYYY-MM-DDTHH:mm) to PostgreSQL timestamp format
    // datetime-local sends "2025-11-05T10:00", PostgreSQL needs "2025-11-05 10:00:00"
    const formatDateTime = (datetimeLocal) => {
        if (!datetimeLocal) return null;
        // Replace T with space and add seconds if not present
        return datetimeLocal.replace('T', ' ') + ':00';
    };
    
    const formattedStartTime = formatDateTime(startTime);
    const formattedEndTime = formatDateTime(endTime);
    
    // Validate that end time is after start time
    if (new Date(formattedEndTime) <= new Date(formattedStartTime)) {
        return knex.select("eventtypeid", "eventtypename")
            .from("eventtypes")
            .then(eventTypes => {
                res.render("adminCreate", { 
                    eventTypes: eventTypes || [], 
                    error_message: "End time must be after start time.",
                    formData
                });
            })
            .catch(() => {
                res.redirect("/admin/dashboard");
            });
    }
    
    knex("events")
        .insert({
            eventname: eventName.trim(),
            eventdescription: eventDescription ? eventDescription.trim() : null,
            starttime: formattedStartTime,
            endtime: formattedEndTime,
                eventlocation: locationValue || null,
            eventhost: eventHost ? eventHost.trim() : null,
            eventurl: eventurl ? eventurl.trim() : null,
            eventlinktext: (eventlinktext && typeof eventlinktext === 'string' && eventlinktext.trim() !== '') ? eventlinktext.trim() : null,
            eventtypeid: parseInt(eventTypeID)
        })
        .then(() => {
            console.log("Event created successfully with linktext:", eventlinktext);
            res.redirect("/admin/dashboard");
        })
        .catch(err => {
            console.error("Failed to create event:", err);
            // Reload form with error
            knex.select("eventtypeid", "eventtypename")
                .from("eventtypes")
                .then(eventTypes => {
                    res.render("adminCreate", { 
                        eventTypes: eventTypes || [], 
                            error_message: "Failed to create event. Please check your input and try again. Error: " + (err.message || "Unknown error"),
                            formData
                    });
                })
                .catch(() => {
                    res.redirect("/admin/dashboard");
                });
        });
});

// Admin Edit Event - Show form
app.get("/admin/edit/:id", requireAdmin, (req, res) => {
    const eventId = req.params.id;
    
    // Get event and event types
    Promise.all([
        knex.select("*").from("events").where("eventid", eventId).first(),
        knex.select("eventtypeid", "eventtypename").from("eventtypes").orderBy("eventtypename", "asc")
    ])
    .then(([event, eventTypes]) => {
        if (!event) {
            return res.redirect("/admin/dashboard");
        }
        // Debug: Log loaded event data
        console.log("Loading event for edit - eventlinktext:", event.eventlinktext);
        // Ensure eventTypes is always an array
        res.render("adminEdit", { event: event, eventTypes: eventTypes || [] });
    })
    .catch(err => {
        console.error("Failed to load event:", err);
        res.redirect("/admin/dashboard");
    });
});

// Admin Edit Event - Handle form submission with file upload
app.post("/admin/edit/:id", requireAdmin, (req, res) => {
    const eventId = req.params.id;
    const { eventName, eventDescription, startTime, endTime, eventLocation, eventHost, eventTypeID, eventurl, eventlinktext } = req.body;
    const locationValue = eventLocation ? eventLocation.trim() : '';
    
    // Debug: Log the form data
    console.log("Edit Event Form Data:", {
        eventId,
        eventurl,
        eventlinktext,
        allBody: req.body
    });
    
    // Basic validation
    if (!eventName || !startTime || !endTime || !eventTypeID || !locationValue) {
        // Reload edit form with error
        return Promise.all([
            knex.select("*").from("events").where("eventid", eventId).first(),
            knex.select("eventtypeid", "eventtypename").from("eventtypes").orderBy("eventtypename", "asc")
        ])
        .then(([event, eventTypes]) => {
            if (!event) {
                return res.redirect("/admin/dashboard");
            }
            res.render("adminEdit", { 
                event: event, 
                eventTypes: eventTypes || [], 
                error_message: "Please fill in all required fields (Event Name, Start Time, End Time, Location, Event Type)." 
            });
        })
        .catch(() => {
            res.redirect("/admin/dashboard");
        });
    }
    
    // Convert datetime-local format (YYYY-MM-DDTHH:mm) to PostgreSQL timestamp format
    const formatDateTime = (datetimeLocal) => {
        if (!datetimeLocal) return null;
        // Replace T with space and add seconds if not present
        return datetimeLocal.replace('T', ' ') + ':00';
    };
    
    const formattedStartTime = formatDateTime(startTime);
    const formattedEndTime = formatDateTime(endTime);
    
    // Validate that end time is after start time
    if (new Date(formattedEndTime) <= new Date(formattedStartTime)) {
        return Promise.all([
            knex.select("*").from("events").where("eventid", eventId).first(),
            knex.select("eventtypeid", "eventtypename").from("eventtypes").orderBy("eventtypename", "asc")
        ])
        .then(([event, eventTypes]) => {
            if (!event) {
                return res.redirect("/admin/dashboard");
            }
            res.render("adminEdit", { 
                event: event, 
                eventTypes: eventTypes || [], 
                error_message: "End time must be after start time." 
            });
        })
        .catch(() => {
            res.redirect("/admin/dashboard");
        });
    }
    
    // Prepare update data
    const updateData = {
        eventname: eventName.trim(),
        eventdescription: eventDescription ? eventDescription.trim() : null,
        starttime: formattedStartTime,
        endtime: formattedEndTime,
        eventlocation: locationValue || null,
        eventhost: eventHost ? eventHost.trim() : null,
        eventurl: eventurl ? eventurl.trim() : null,
        eventlinktext: (eventlinktext && typeof eventlinktext === 'string' && eventlinktext.trim() !== '') ? eventlinktext.trim() : null,
        eventtypeid: parseInt(eventTypeID)
    };
    
    // Update event
    knex.select("*").from("events").where("eventid", eventId).first()
        .then(event => {
            if (!event) {
                return res.redirect("/admin/dashboard");
            }
            
            // Debug: Log update data
            console.log("Updating event with data:", updateData);
            
            // Update event with new data
            return knex("events")
                .where("eventid", eventId)
                .update(updateData)
                .then((rowsUpdated) => {
                    console.log("Event updated successfully. Rows affected:", rowsUpdated);
                    res.redirect("/admin/dashboard");
                })
                .catch((updateErr) => {
                    console.error("Database update error:", updateErr);
                    throw updateErr;
                });
        })
        .catch(err => {
            console.error("Failed to update event:", err);
            // Reload edit form with error
            Promise.all([
                knex.select("*").from("events").where("eventid", eventId).first(),
                knex.select("eventtypeid", "eventtypename").from("eventtypes").orderBy("eventtypename", "asc")
            ])
            .then(([event, eventTypes]) => {
                if (!event) {
                    return res.redirect("/admin/dashboard");
                }
                res.render("adminEdit", { 
                    event: event, 
                    eventTypes: eventTypes || [], 
                    error_message: "Failed to update event. Please check your input and try again. Error: " + (err.message || "Unknown error")
                });
            })
            .catch(() => {
                res.redirect("/admin/dashboard");
            });
        });
});

// Admin Delete Event
app.post("/admin/delete/:id", requireAdmin, (req, res) => {
    const eventId = req.params.id;
    
    knex("events")
        .where("eventid", eventId)
        .del()
        .then(() => {
            res.redirect("/admin/dashboard");
        })
        .catch(err => {
            console.error("Failed to delete event:", err);
            res.redirect("/admin/dashboard");
        });
});

// Note: /users route removed to keep the project minimal for assignment requirements.


app.listen(port, '0.0.0.0', () => {
    console.log(`Server is listening on port ${port}`);
});
