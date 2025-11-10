# EventTypes Table Setup Instructions

## Overview

The `eventtypes` table stores the categories/types of events that can be created. The dropdown menus on the create and edit event pages automatically pull event types from this table.

## Quick Start

1. **Open pgAdmin** and connect to your PostgreSQL server
2. **Select your database** (e.g., `foodisus`)
3. **Open Query Tool** (right-click database → Query Tool)
4. **Run one of the SQL scripts**:
   - `update_eventtypes_simple.sql` - Quick script with standard event types
   - `update_eventtypes.sql` - Comprehensive script with instructions

## SQL Scripts Provided

### 1. `update_eventtypes_simple.sql` (Recommended for Quick Setup)
- Simple, one-command script
- Inserts 10 standard event types
- Safe to run multiple times (won't create duplicates)
- Includes a SELECT statement to verify results

### 2. `update_eventtypes.sql` (Comprehensive)
- Detailed script with comments
- Includes instructions for adding custom event types
- Includes instructions for updating/deleting event types
- Safe to run multiple times

## Standard Event Types Included

The scripts will create these event types (if they don't already exist):
1. Career
2. Networking
3. Workshop
4. Social
5. Conference
6. Seminar
7. Training
8. Meeting
9. Webinar
10. Other

## How It Works

### Database Integration
- The `eventtypes` table has a `UNIQUE` constraint on `eventtypename`
- The scripts use `ON CONFLICT DO NOTHING` to prevent duplicates
- Safe to run multiple times without errors

### Application Integration
- **Create Event Page** (`/admin/create`): Automatically loads event types from database
- **Edit Event Page** (`/admin/edit/:id`): Automatically loads event types from database
- Event types are displayed in alphabetical order
- If no event types exist, a warning message is shown

## Adding Custom Event Types

### Method 1: Using pgAdmin
```sql
INSERT INTO eventtypes (eventtypename) 
VALUES ('Your Custom Type')
ON CONFLICT (eventtypename) DO NOTHING;
```

### Method 2: Using the SQL Script
Edit `update_eventtypes.sql` and add:
```sql
INSERT INTO eventtypes (eventtypename) VALUES
    ('Your Custom Type')
ON CONFLICT (eventtypename) DO NOTHING;
```

## Updating Event Type Names

```sql
-- Update an existing event type name
UPDATE eventtypes 
SET eventtypename = 'New Name' 
WHERE eventtypename = 'Old Name';
```

**Note**: This will update the name for all events using this type.

## Deleting Event Types

⚠️ **WARNING**: Only delete event types if no events are using them!

### Step 1: Check if any events are using this type
```sql
SELECT COUNT(*) 
FROM events 
WHERE eventtypeid = (
    SELECT eventtypeid 
    FROM eventtypes 
    WHERE eventtypename = 'Type Name'
);
```

### Step 2: If count is 0, delete the type
```sql
DELETE FROM eventtypes 
WHERE eventtypename = 'Type Name';
```

### Step 3: If count is > 0, update events first
```sql
-- Update events to use a different type
UPDATE events 
SET eventtypeid = (SELECT eventtypeid FROM eventtypes WHERE eventtypename = 'Other')
WHERE eventtypeid = (SELECT eventtypeid FROM eventtypes WHERE eventtypename = 'Type to Delete');

-- Then delete the type
DELETE FROM eventtypes 
WHERE eventtypename = 'Type to Delete';
```

## Verifying Event Types

### View All Event Types
```sql
SELECT * FROM eventtypes ORDER BY eventtypename;
```

### View Event Types with Event Counts
```sql
SELECT 
    et.eventtypeid,
    et.eventtypename,
    COUNT(e.eventid) as event_count
FROM eventtypes et
LEFT JOIN events e ON et.eventtypeid = e.eventtypeid
GROUP BY et.eventtypeid, et.eventtypename
ORDER BY et.eventtypename;
```

## Troubleshooting

### Issue: Dropdown shows "No event types available"
**Solution**: Run the `update_eventtypes.sql` or `update_eventtypes_simple.sql` script to populate the table.

### Issue: Duplicate event types
**Solution**: The scripts use `ON CONFLICT DO NOTHING`, so duplicates won't be created. If you manually created duplicates, you can remove them:
```sql
-- Find duplicates
SELECT eventtypename, COUNT(*) 
FROM eventtypes 
GROUP BY eventtypename 
HAVING COUNT(*) > 1;

-- Delete duplicates (keep the one with the lowest ID)
DELETE FROM eventtypes 
WHERE eventtypeid NOT IN (
    SELECT MIN(eventtypeid) 
    FROM eventtypes 
    GROUP BY eventtypename
);
```

### Issue: Event type not showing in dropdown
**Solution**: 
1. Verify the event type exists: `SELECT * FROM eventtypes;`
2. Check for typos in the event type name
3. Restart your Node.js server to refresh the database connection
4. Clear your browser cache and refresh the page

### Issue: Cannot create event - "No event types available"
**Solution**: 
1. Run the SQL script to populate event types
2. Verify event types exist: `SELECT * FROM eventtypes;`
3. Check that the `eventtypes` table exists and has the correct structure

## Table Structure

The `eventtypes` table has the following structure:
```sql
CREATE TABLE eventtypes (
    eventtypeid SERIAL PRIMARY KEY,
    eventtypename VARCHAR(100) NOT NULL UNIQUE
);
```

## Best Practices

1. **Use Descriptive Names**: Event type names should be clear and descriptive
2. **Keep It Simple**: Don't create too many event types (10-15 is usually enough)
3. **Use "Other"**: Always include an "Other" type for events that don't fit categories
4. **Don't Delete Frequently Used Types**: Check usage before deleting
5. **Update Instead of Delete**: If you want to rename a type, update it rather than deleting and recreating

## Integration with Application

### Create Event Page
- Route: `GET /admin/create`
- Query: `SELECT eventtypeid, eventtypename FROM eventtypes ORDER BY eventtypename`
- Display: Dropdown menu with all event types

### Edit Event Page
- Route: `GET /admin/edit/:id`
- Query: `SELECT eventtypeid, eventtypename FROM eventtypes ORDER BY eventtypename`
- Display: Dropdown menu with all event types (current event's type is pre-selected)

### Public Events Page
- Event types are displayed with each event
- Filtering by event type can be implemented in the future

## Next Steps

After running the SQL script:
1. Restart your Node.js server (if running)
2. Navigate to `/admin/create` to verify the dropdown shows event types
3. Create a test event to verify everything works
4. Check the public events page to see event types displayed

## Support

If you encounter issues:
1. Check the database connection in your `.env` file
2. Verify the `eventtypes` table exists and has data
3. Check the server console for error messages
4. Verify your database credentials are correct

