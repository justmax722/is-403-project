//npm install dotenv - explain
//npm install express-session - explain
//create the .env file

// Load environment variables from .env file into memory
// Allows you to use process.env
require('dotenv').config();

const express = require("express");

//Needed for the session variable - Stored on the server to hold data
const session = require("express-session");

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

const knex = require("knex")({
    client: "pg",
    connection: {
        host : process.env.DB_HOST || "localhost",
        user : process.env.DB_USER || "postgres",
        password : process.env.DB_PASSWORD || "admin",
        database : process.env.DB_NAME || "foodisus",
        port : process.env.DB_PORT || 5432  // PostgreSQL 16 typically uses port 5434
    }
});

// Tells Express how to read form data sent in the body of a request
app.use(express.urlencoded({extended: true}));

// Serve static files from public directory (for CSS, images, etc.)
// This must come BEFORE authentication middleware so CSS/images load without login
app.use(express.static("public"));

// Global authentication middleware - runs on EVERY request
// Note: Static files are served by express.static above, so CSS/images load without auth
// If a static file doesn't exist, express.static calls next() and the request continues here
app.use((req, res, next) => {
    // Skip authentication for public routes
    if (req.path === '/' || req.path === '/login' || req.path === '/logout' || req.path === '/events') {
        //continue with the request path
        return next();
    }
    
    // Check if user is logged in for all other routes (including /admin/*)
    if (req.session.isLoggedIn) {
        //notice no return because nothing below it
        next(); // User is logged in, continue
    } 
    else {
        res.render("login", { error_message: "Please log in to access this page" });
    }
});

// Main page route - redirect to admin dashboard if logged in, otherwise show login
app.get("/", (req, res) => {
    // Check if user is logged in
    if (req.session.isLoggedIn) {
        // Redirect to admin dashboard
        res.redirect("/admin/dashboard");
    } 
    else {
        res.render("login", { error_message: "" });
    }
});

// Public events page - no login required
app.get("/events", (req, res) => {
    // Get filter parameters from query string
    const startDate = req.query.startDate;
    const endDate = req.query.endDate;
    const categories = req.query.categories ? (Array.isArray(req.query.categories) ? req.query.categories : [req.query.categories]) : [];
    const format = req.query.format || 'grid';
    
    // Query event types for category filter
    const eventTypesQuery = knex.select("eventtypeid", "eventtypename")
        .from("eventtypes")
        .orderBy("eventtypename", "asc");
    
    // Build events query
    let eventsQuery = knex.select(
        "events.eventid",
        "events.eventname",
        "events.eventdescription",
        "events.starttime",
        "events.endtime",
        "events.eventlocation",
        "events.eventhost",
        "events.eventtypeid",
        "eventtypes.eventtypename"
    )
    .from("events")
    .leftJoin("eventtypes", "events.eventtypeid", "eventtypes.eventtypeid")
    .where("events.endtime", ">", knex.fn.now()); // Only show future events
    
    // Apply date filters
    // If only startDate is provided, show events from that date onward
    // If only endDate is provided, show events up to that date
    // If both are provided, show events within that range
    if (startDate && endDate) {
        // Date range: events that overlap with the selected range
        // An event overlaps if: event starts before range ends AND event ends after range starts
        eventsQuery = eventsQuery.where("events.starttime", "<=", endDate + " 23:59:59")
                                  .where("events.endtime", ">=", startDate + " 00:00:00");
    } else if (startDate) {
        // Only start date: show events that end on or after this date
        eventsQuery = eventsQuery.where("events.endtime", ">=", startDate + " 00:00:00");
    } else if (endDate) {
        // Only end date: show events that start on or before this date
        eventsQuery = eventsQuery.where("events.starttime", "<=", endDate + " 23:59:59");
    }
    
    // Apply category filters
    if (categories.length > 0) {
        eventsQuery = eventsQuery.whereIn("events.eventtypeid", categories.map(id => parseInt(id)));
    }
    
    eventsQuery = eventsQuery.orderBy("events.starttime", "asc");
    
    // Execute both queries
    Promise.all([eventTypesQuery, eventsQuery])
        .then(([eventTypes, events]) => {
            res.render("events", { 
                events: events || [], 
                eventTypes: eventTypes || [],
                currentFilters: {
                    startDate: startDate || '',
                    endDate: endDate || '',
                    categories: categories,
                    format: format
                }
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
                    format: format
                },
                error_message: "Failed to load events." 
            });
        });
});

// This creates attributes in the session object to keep track of user and if they logged in
app.post("/login", (req, res) => {
    let sName = req.body.username;
    let sPassword = req.body.password;
    
    knex.select("username", "password")
    .from('users')
    .where("username", sName)
    .andWhere("password", sPassword)
    .then(users => {
      // Check if a user was found with matching username AND password
      if (users.length > 0) {
        req.session.isLoggedIn = true;
        req.session.username = sName;
        res.redirect("/admin/dashboard");
      } else {
        // No matching user found
        res.render("login", { error_message: "Invalid login" });
      }
    })
    .catch(err => {
      console.error("Login error:", err);
      res.render("login", { error_message: "Invalid login" });
    });

});

// Logout route
app.get("/logout", (req, res) => {
    // Get rid of the session object
    req.session.destroy((err) => {
        if (err) {
            console.log(err);
        }
        res.redirect("/");
    });
});

// ============================================
// ADMIN ROUTES - All require authentication
// ============================================

// Admin Dashboard - List all events
app.get("/admin/dashboard", (req, res) => {
    // Query events with event type names
    knex.select(
        "events.eventid",
        "events.eventname",
        "events.starttime",
        "events.endtime",
        "events.eventlocation",
        "events.eventhost",
        "eventtypes.eventtypename as typename"
    )
    .from("events")
    .leftJoin("eventtypes", "events.eventtypeid", "eventtypes.eventtypeid")
    .orderBy("events.starttime", "asc")
    .then(events => {
        // Ensure events is always an array
        res.render("adminDashboard", { events: events || [] });
    })
    .catch(err => {
        console.error("Failed to load events:", err);
        res.render("adminDashboard", { events: [], error_message: "Database error loading events." });
    });
});

// Admin Create Event - Show form
app.get("/admin/create", (req, res) => {
    // Get event types for dropdown
    knex.select("eventtypeid", "eventtypename")
        .from("eventtypes")
        .orderBy("eventtypename", "asc")
        .then(eventTypes => {
            // Ensure eventTypes is always an array
            res.render("adminCreate", { eventTypes: eventTypes || [] });
        })
        .catch(err => {
            console.error("Failed to load event types:", err);
            res.render("adminCreate", { eventTypes: [], error_message: "Database error loading event types." });
        });
});

// Admin Create Event - Handle form submission
app.post("/admin/create", (req, res) => {
    const { eventName, eventDescription, startTime, endTime, eventLocation, eventHost, eventTypeID } = req.body;
    
    // Basic validation
    if (!eventName || !startTime || !endTime || !eventTypeID) {
        return knex.select("eventtypeid", "eventtypename")
            .from("eventtypes")
            .then(eventTypes => {
                res.render("adminCreate", { 
                    eventTypes: eventTypes || [], 
                    error_message: "Please fill in all required fields (Event Name, Start Time, End Time, Event Type)." 
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
                    error_message: "End time must be after start time." 
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
            eventlocation: eventLocation ? eventLocation.trim() : null,
            eventhost: eventHost ? eventHost.trim() : null,
            eventtypeid: parseInt(eventTypeID)
        })
        .then(() => {
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
                        error_message: "Failed to create event. Please check your input and try again. Error: " + (err.message || "Unknown error")
                    });
                })
                .catch(() => {
                    res.redirect("/admin/dashboard");
                });
        });
});

// Admin Edit Event - Show form
app.get("/admin/edit/:id", (req, res) => {
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
        // Ensure eventTypes is always an array
        res.render("adminEdit", { event: event, eventTypes: eventTypes || [] });
    })
    .catch(err => {
        console.error("Failed to load event:", err);
        res.redirect("/admin/dashboard");
    });
});

// Admin Edit Event - Handle form submission
app.post("/admin/edit/:id", (req, res) => {
    const eventId = req.params.id;
    const { eventName, eventDescription, startTime, endTime, eventLocation, eventHost, eventTypeID } = req.body;
    
    // Basic validation
    if (!eventName || !startTime || !endTime || !eventTypeID) {
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
                error_message: "Please fill in all required fields (Event Name, Start Time, End Time, Event Type)." 
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
    
    knex("events")
        .where("eventid", eventId)
        .update({
            eventname: eventName.trim(),
            eventdescription: eventDescription ? eventDescription.trim() : null,
            starttime: formattedStartTime,
            endtime: formattedEndTime,
            eventlocation: eventLocation ? eventLocation.trim() : null,
            eventhost: eventHost ? eventHost.trim() : null,
            eventtypeid: parseInt(eventTypeID)
        })
        .then(() => {
            res.redirect("/admin/dashboard");
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
app.post("/admin/delete/:id", (req, res) => {
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


app.listen(port, () => {
    console.log("The server is listening");
});
