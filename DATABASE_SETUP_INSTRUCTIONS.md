# Database Setup Instructions

## Quick Start

1. **Open pgAdmin** and connect to your PostgreSQL server
2. **Select your database** (e.g., `foodisus` or create a new one)
3. **Open Query Tool** (right-click database → Query Tool)
4. **Copy and paste** the contents of `database_setup.sql`
5. **Execute** the script (F5 or click Execute)

## Files Provided

### 1. `database_setup.sql` (Recommended)
- Creates all tables with constraints
- Inserts sample event types
- Inserts sample events for testing
- Includes a test user (admin/admin)
- Ready to use immediately

### 2. `database_setup_minimal.sql`
- Creates tables only (no sample data)
- Includes one event type and one user
- Use this if you want to start with empty tables

## Table Structure

### `eventtypes` Table
- `eventtypeid` (SERIAL PRIMARY KEY) - Auto-incrementing ID
- `eventtypename` (VARCHAR(100)) - Name of event type (e.g., "Career", "Workshop")

### `events` Table
- `eventid` (SERIAL PRIMARY KEY) - Auto-incrementing ID
- `eventname` (VARCHAR(200)) - Name of the event (required)
- `eventdescription` (TEXT) - Event description (optional)
- `starttime` (TIMESTAMP) - Event start time (required)
- `endtime` (TIMESTAMP) - Event end time (required)
- `eventlocation` (VARCHAR(200)) - Event location (optional)
- `eventhost` (VARCHAR(200)) - Event host/organizer (optional)
- `eventtypeid` (INTEGER) - Foreign key to eventtypes table (required)
- **Constraint**: End time must be after start time

### `users` Table
- `id` (SERIAL PRIMARY KEY) - Auto-incrementing ID
- `username` (VARCHAR(50)) - Username for login (unique)
- `password` (VARCHAR(50)) - Password for login (stored as plain text - change in production!)

## Default Credentials

After running the setup script:
- **Username**: `justmax`
- **Password**: `admin`

⚠️ **IMPORTANT**: Change the default password before deploying to production!

## Sample Data

The `database_setup.sql` script includes:

### Event Types (10 total):
- Career
- Networking
- Workshop
- Social
- Conference
- Seminar
- Training
- Meeting
- Webinar
- Other

**Note**: Event types are automatically inserted when you run the setup script. The dropdown menus on the create/edit event pages will automatically pull from the database.

### Sample Events:
- Tech Career Fair
- AIS Club Networking Night
- Python Automation Workshop
- Data Visualization Challenge
- IS Holiday Social

### Test User:
- Username: `justmax`
- Password: `admin`

## Verifying the Setup

After running the script, you can verify with these queries:

```sql
-- Check event types
SELECT * FROM eventtypes;

-- Check events
SELECT * FROM events;

-- Check users
SELECT * FROM users;

-- View events with their types
SELECT 
    e.eventid,
    e.eventname,
    e.starttime,
    e.endtime,
    e.eventlocation,
    e.eventhost,
    et.eventtypename
FROM events e
LEFT JOIN eventtypes et ON e.eventtypeid = et.eventtypeid
ORDER BY e.starttime;
```

## Troubleshooting

### Error: "relation already exists"
- The tables already exist. Use `DROP TABLE` commands first or use the provided script which includes DROP statements.

### Error: "foreign key constraint"
- Make sure `eventtypes` table is created before `events` table
- Make sure you have at least one event type before creating events

### Error: "check constraint violation"
- The end time must be after the start time for events

### Cannot login
- Verify the users table has data: `SELECT * FROM users;`
- Make sure you're using the correct username and password
- Check that passwords match exactly (case-sensitive)

## Next Steps

1. **Change the default password**:
   ```sql
   UPDATE users SET password = 'your_new_password' WHERE username = 'justmax';
   ```

2. **Add more event types** (if needed):
   ```sql
   INSERT INTO eventtypes (eventtypename) VALUES ('Your Event Type');
   ```

3. **Add more users** (if needed):
   ```sql
   INSERT INTO users (username, password) VALUES ('username', 'password');
   ```

4. **Start the application**:
   ```bash
   node index.js
   ```

5. **Test the application**:
   - Navigate to `http://localhost:3000`
   - Login with justmax/admin
   - Create, edit, and delete events
   - View public events page at `http://localhost:3000/events`

## Security Notes

⚠️ **Production Warnings**:
- Passwords are stored as plain text in this setup
- In production, use password hashing (bcrypt, etc.)
- Use environment variables for database credentials
- Implement proper authentication and authorization
- Use HTTPS in production
- Validate and sanitize all user inputs

## Database Maintenance

### Backup Database
```bash
pg_dump -U postgres -d foodisus > backup.sql
```

### Restore Database
```bash
psql -U postgres -d foodisus < backup.sql
```

### Clear All Events
```sql
DELETE FROM events;
```

### Clear All Data (Keep Tables)
```sql
DELETE FROM events;
DELETE FROM eventtypes;
DELETE FROM users;
-- Then re-insert at least one event type and one user
```

