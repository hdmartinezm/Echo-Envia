-- =============================================================
-- Echo Envia - Database Initialization Script
-- MySQL Flexible Server: mysql-echo-envia-dev-a074ba49
-- Run as: enviaadmin (server admin)
-- =============================================================

-- Create application database
CREATE DATABASE IF NOT EXISTS envia_delivery
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Create application user
-- IMPORTANT: Replace <DB_PASSWORD> with the actual password from Azure Key Vault or pipeline secrets
-- Do NOT use bash heredoc or shell variables to pass the password - use Python/az rest instead
CREATE USER IF NOT EXISTS 'echoadmin'@'%' IDENTIFIED BY '<DB_PASSWORD>';
ALTER USER 'echoadmin'@'%' IDENTIFIED BY '<DB_PASSWORD>';

-- Grant permissions
GRANT ALL PRIVILEGES ON envia_delivery.* TO 'echoadmin'@'%';
FLUSH PRIVILEGES;

-- Verify
SELECT user, host FROM mysql.user WHERE user = 'echoadmin';
SHOW GRANTS FOR 'echoadmin'@'%';
