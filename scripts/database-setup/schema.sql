-- ABC Company Database Schema Setup
-- MySQL database schema for the multi-tier web application

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS intel;
USE intel;

-- Create main data table for web application
CREATE TABLE IF NOT EXISTS data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firstname VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create index for better performance
CREATE INDEX idx_email ON data(email);
CREATE INDEX idx_created_at ON data(created_at);

-- Insert sample data for testing
INSERT INTO data (firstname, email) VALUES 
('John', 'john.doe@example.com'),
('Jane', 'jane.smith@example.com'),
('Bob', 'bob.wilson@example.com')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- Create a user for application connections (optional)
-- CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'secure_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON intel.* TO 'appuser'@'%';
-- FLUSH PRIVILEGES;

-- Show table structure
DESCRIBE data;

-- Show sample data
SELECT * FROM data LIMIT 5;