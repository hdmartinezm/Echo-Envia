const mysql = require('mysql2/promise');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

class DatabaseConfig {
  constructor() {
    this.pool = null;
    this.keyVaultClient = null;
    this.initializeKeyVault();
  }

  async initializeKeyVault() {
    try {
      const credential = new DefaultAzureCredential();
      const keyVaultUrl = process.env.KEY_VAULT_URL;
      
      if (keyVaultUrl) {
        this.keyVaultClient = new SecretClient(keyVaultUrl, credential);
      }
    } catch (error) {
      console.warn('Key Vault initialization failed:', error.message);
    }
  }

  async getSecret(secretName) {
    if (this.keyVaultClient) {
      try {
        const secret = await this.keyVaultClient.getSecret(secretName);
        return secret.value;
      } catch (error) {
        console.warn(`Failed to get secret ${secretName}:`, error.message);
      }
    }
    return null;
  }

  async createPool() {
    if (this.pool) {
      return this.pool;
    }

    try {
      // Intentar obtener credenciales de Key Vault primero
      const dbPassword = await this.getSecret('mysql-password') || process.env.DB_PASSWORD;
      const dbUser = await this.getSecret('mysql-username') || process.env.DB_USER || 'adminuser';

      const config = {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 3306,
        user: dbUser,
        password: dbPassword,
        database: process.env.DB_NAME || 'webapp',
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
        acquireTimeout: 60000,
        timeout: 60000,
        reconnect: true,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
      };

      this.pool = mysql.createPool(config);
      
      // Test connection
      const connection = await this.pool.getConnection();
      await connection.ping();
      connection.release();
      
      console.log('Database connection pool created successfully');
      return this.pool;
      
    } catch (error) {
      console.error('Failed to create database pool:', error);
      throw error;
    }
  }

  async getConnection() {
    if (!this.pool) {
      await this.createPool();
    }
    return this.pool.getConnection();
  }

  async query(sql, params = []) {
    if (!this.pool) {
      await this.createPool();
    }
    
    try {
      const [results] = await this.pool.execute(sql, params);
      return results;
    } catch (error) {
      console.error('Database query error:', error);
      throw error;
    }
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      this.pool = null;
    }
  }
}

module.exports = new DatabaseConfig();