-- ============================================
-- Users Table Creation Script
-- Standalone script to create users table and insert justmax user
-- ============================================

-- Drop users table if it exists
-- WARNING: This will delete all existing users!
DROP TABLE IF EXISTS users CASCADE;

-- Create Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(50) NOT NULL
);

-- Insert justmax user
-- Default credentials: username='justmax', password='admin'
INSERT INTO users (username, password) VALUES ('justmax', 'admin');

-- Verify the user was created
SELECT * FROM users;

-- ============================================
-- Script Complete!
-- ============================================
-- You can now login with:
-- Username: justmax
-- Password: admin
--
-- Remember to change the password in production!

