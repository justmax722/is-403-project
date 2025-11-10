# IS-403 Project Setup Guide

## Installation Steps

1. **Clone the repository into Github Desktop** (if not already done)
   ```  
   Go to the github repo and open with Github Desktop
   ```

2. **Install all dependencies**
   ```
   npm install
   ```
   This will automatically install all packages listed in package.json:
   - dotenv
   - ejs
   - express
   - express-session
   - knex
   - pg
   - init

3. **Set up environment variables**
   - Copy the `.env.example` file to `.env`
   - Update the `.env` file with your database credentials and session secret
   ```
   cp .env.example .env
   ```
   Then edit `.env` with your actual values.

4. **Set up your PostgreSQL database**
   - Make sure PostgreSQL is running
   - Create a database named "foodisus" (or update DB_NAME in .env)
   - Ensure the database has the required tables (users, pokemon)

5. **Start the server**
   ```
   node index.js
   ```

6. **Access the application**
   - Open your browser and go to: http://localhost:3000
