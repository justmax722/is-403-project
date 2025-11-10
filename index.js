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

// Global authentication middleware - runs on EVERY request
app.use((req, res, next) => {
    // Skip authentication for login routes
    if (req.path === '/' || req.path === '/login' || req.path === '/logout') {
        //continue with the request path
        return next();
    }
    
    // Check if user is logged in for all other routes
    if (req.session.isLoggedIn) {
        //notice no return because nothing below it
        next(); // User is logged in, continue
    } 
    else {
        res.render("login", { error_message: "Please log in to access this page" });
    }
});

// Main page route - load full pokemon list (ordered by name) when logged in
app.get("/", (req, res) => {
    // Check if user is logged in
    if (req.session.isLoggedIn) {
        // Query all pokemon ordered by description (name)
        knex.select("id", "description", "base_total")
            .from("pokemon")
            .orderBy("description", "asc")
            .then(pokemon => {
                res.render("index", { pokemon: pokemon, error_message: "", username: req.session && req.session.username });
            })
            .catch(err => {
                console.error("Failed to load pokemon:", err);
                res.render("index", { pokemon: [], error_message: "Database error loading pokemon.", username: req.session && req.session.username });
            });
    } 
    else {
        res.render("login", { error_message: "" });
    }
});

// Handle search on the same page (form posts to "/")
app.post("/", (req, res) => {
    if (!req.session.isLoggedIn) {
        return res.render("login", { error_message: "" });
    }

    const name = (req.body.name || "").trim();
    // Prepare queries: full list + search
    const listQuery = knex.select("id", "description", "base_total").from("pokemon").orderBy("description", "asc");

    if (!name) {
        // Reload list with an error message
        return listQuery
            .then(pokemon => res.render("index", { pokemon, error_message: "Please enter a Pokemon name.", username: req.session && req.session.username }))
            .catch(err => {
                console.error("DB error:", err);
                res.render("index", { pokemon: [], error_message: "Database error.", username: req.session && req.session.username });
            });
    }

    // Only search and render a dedicated searchResult view per project requirements
    knex.select("description", "base_total")
        .from("pokemon")
        .whereRaw("LOWER(description) = LOWER(?)", [name])
        .then(rows => {
            if (rows.length > 0) {
                res.render("searchResult", { pokemon: rows[0], error_message: "", username: req.session && req.session.username });
            } else {
                res.render("searchResult", { pokemon: null, error_message: "Pokemon not found.", username: req.session && req.session.username });
            }
        })
        .catch(err => {
            console.error("Search error:", err);
            res.render("searchResult", { pokemon: null, error_message: "Database error during search.", username: req.session && req.session.username });
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
        res.redirect("/");
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


// Note: /users route removed to keep the project minimal for assignment requirements.


app.listen(port, () => {
    console.log("The server is listening");
});
