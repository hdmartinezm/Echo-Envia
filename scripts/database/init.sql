-- Inicialización de base de datos para Azure Web Project
-- Este script crea las tablas básicas necesarias

-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS webapp;
USE webapp;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
);

-- Tabla de sesiones (para manejo de sesiones)
CREATE TABLE IF NOT EXISTS user_sessions (
    id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
);

-- Tabla de logs de aplicación
CREATE TABLE IF NOT EXISTS app_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    level ENUM('ERROR', 'WARN', 'INFO', 'DEBUG') NOT NULL,
    message TEXT NOT NULL,
    metadata JSON,
    user_id INT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_level (level),
    INDEX idx_created_at (created_at),
    INDEX idx_user_id (user_id)
);

-- Tabla de configuración de aplicación
CREATE TABLE IF NOT EXISTS app_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key),
    INDEX idx_is_active (is_active)
);

-- Insertar datos de ejemplo
INSERT INTO users (username, email, first_name, last_name) VALUES
('admin', 'admin@example.com', 'Admin', 'User'),
('testuser', 'test@example.com', 'Test', 'User')
ON DUPLICATE KEY UPDATE username = username;

-- Insertar configuración inicial
INSERT INTO app_config (config_key, config_value, description) VALUES
('app_name', 'Azure Web Project', 'Nombre de la aplicación'),
('maintenance_mode', 'false', 'Modo de mantenimiento'),
('max_login_attempts', '5', 'Máximo número de intentos de login'),
('session_timeout', '3600', 'Timeout de sesión en segundos')
ON DUPLICATE KEY UPDATE config_key = config_key;

-- Crear usuario para ProxySQL (si se usa)
CREATE USER IF NOT EXISTS 'proxysql'@'%' IDENTIFIED BY 'proxysql_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON webapp.* TO 'proxysql'@'%';

-- Crear usuario de solo lectura para reportes
CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'readonly_password';
GRANT SELECT ON webapp.* TO 'readonly'@'%';

FLUSH PRIVILEGES;