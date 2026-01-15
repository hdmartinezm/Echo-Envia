const express = require('express');
const router = express.Router();
const dbConfig = require('../config/database');

// Root API endpoint
router.get('/', (req, res) => {
  res.json({
    message: 'Azure Web Project API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      users: '/api/users',
      database: '/api/database/test'
    }
  });
});

// Database test endpoint
router.get('/database/test', async (req, res) => {
  try {
    await dbConfig.createPool();
    const result = await dbConfig.query('SELECT 1 as test');
    
    res.json({
      status: 'success',
      message: 'Database connection successful',
      result: result
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Database connection failed',
      error: error.message
    });
  }
});

// Users endpoints (ejemplo)
router.get('/users', async (req, res) => {
  try {
    const users = await dbConfig.query('SELECT id, username, email, created_at FROM users LIMIT 10');
    res.json({
      status: 'success',
      data: users
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch users',
      error: error.message
    });
  }
});

router.post('/users', async (req, res) => {
  try {
    const { username, email } = req.body;
    
    if (!username || !email) {
      return res.status(400).json({
        status: 'error',
        message: 'Username and email are required'
      });
    }

    const result = await dbConfig.query(
      'INSERT INTO users (username, email) VALUES (?, ?)',
      [username, email]
    );

    res.status(201).json({
      status: 'success',
      message: 'User created successfully',
      userId: result.insertId
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Failed to create user',
      error: error.message
    });
  }
});

// System info endpoint
router.get('/system/info', (req, res) => {
  res.json({
    status: 'success',
    data: {
      nodeVersion: process.version,
      platform: process.platform,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      environment: process.env.NODE_ENV || 'development',
      timestamp: new Date().toISOString()
    }
  });
});

module.exports = router;