# IS Event Calendar - Setup Instructions

Follow these steps to set up the IS Event Calendar application on your local machine.

## Prerequisites

- **Node.js** (v14 or higher) - [Download here](https://nodejs.org/)
- **PostgreSQL** - [Download here](https://www.postgresql.org/download/)
- **pgAdmin** (optional but recommended) - [Download here](https://www.pgadmin.org/download/)

## Step 1: Install Dependencies

Open your terminal in the project directory and run:

```bash
npm install
```

This will install all required packages:
- `dotenv` - For environment variables
- `ejs` - Template engine for views
- `express` - Web framework
- `express-session` - Session management
- `knex` - SQL query builder
- `multer` - File upload handling
- `pg` - PostgreSQL client

## Step 2: Set Up Database

1. Open **pgAdmin** and connect to your PostgreSQL server
2. Create a new database (e.g., `project3` or `eventcalendar`)
3. Right-click your database → **Query Tool**
4. Open and run `database_setup_complete.sql` (or `database_setup_complete_with_comments.sql` for detailed comments)
5. Execute the script (F5 or click Execute)

This will create all necessary tables, indexes, and sample data.

## Step 3: Configure Environment Variables

1. Create a `.env` file in the root directory of the project
2. Add the following content (adjust values to match your database):

```env
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your_password_here
DB_NAME=project3
DB_PORT=5432
SESSION_SECRET=your-secret-key-here
PORT=3000
```

**Important:** Replace `your_password_here` with your PostgreSQL password and `your-secret-key-here` with a random secret string.

## Step 4: Create Required Directories

The application will automatically create the `public/uploads/events/` directory when it starts, but you can create it manually if needed:

```bash
mkdir -p public/uploads/events
```

## Step 5: Start the Server

Run the following command in your terminal:

```bash
node index.js
```

You should see: `The server is listening`

## Step 6: Access the Application

Open your browser and navigate to:
- **Login Page:** http://localhost:3000
- **Public Events:** http://localhost:3000/events

### Default Login Credentials:
- **Email:** `jmaximum72@gmail.com`
- **Password:** `admin`

⚠️ **IMPORTANT:** Change the default password in production!

## Troubleshooting

### Database Connection Issues
- Verify your PostgreSQL server is running
- Check that database credentials in `.env` are correct
- Ensure the database exists

### Port Already in Use
- Change the `PORT` in `.env` to a different port (e.g., 3001)
- Or stop the application using the current port

### Missing Dependencies
- Delete `node_modules` folder and `package-lock.json`
- Run `npm install` again

## Project Structure

```
is-403-project/
├── views/              # EJS templates
│   ├── adminCreate.ejs
│   ├── adminDashboard.ejs
│   ├── adminEdit.ejs
│   ├── events.ejs
│   └── login.ejs
├── public/             # Static files (CSS, images)
│   └── uploads/
│       └── events/     # Uploaded event images
├── database_setup_complete.sql              # Main setup script
├── database_setup_complete_with_comments.sql # Setup script with comments
├── index.js            # Main application file
├── package.json        # Dependencies
└── .env                # Environment variables (create this file)
```

## Next Steps

1. Login with the default credentials
2. Create your first event
3. Test image uploads and links
4. Customize event types as needed

For detailed database information, see `DATABASE_SETUP_INSTRUCTIONS.md`.

