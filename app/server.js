const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// PostgreSQL connection
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: process.env.POSTGRES_PORT || 5432,
  database: process.env.POSTGRES_DB || 'appdb',
  user: process.env.POSTGRES_USER || 'appuser',
  password: process.env.POSTGRES_PASSWORD || 'apppassword',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Initialize database
async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS health_checks (
        id SERIAL PRIMARY KEY,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status VARCHAR(50),
        message TEXT
      )
    `);
    
    await pool.query(`
      INSERT INTO health_checks (status, message) 
      VALUES ('success', 'Database initialized successfully')
    `);
    
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Database initialization error:', error);
  }
}

// Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Frontend status API
app.get('/api/frontend-status', (req, res) => {
  const frontendInfo = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    podName: process.env.HOSTNAME || 'unknown',
    namespace: process.env.POD_NAMESPACE || 'unknown',
    nodeName: process.env.NODE_NAME || 'unknown',
    podIP: process.env.POD_IP || 'unknown',
    environment: {
      NODE_ENV: process.env.NODE_ENV || 'production',
      PORT: PORT,
      POSTGRES_HOST: process.env.POSTGRES_HOST || 'not-set',
      POSTGRES_PORT: process.env.POSTGRES_PORT || 'not-set',
      POSTGRES_DB: process.env.POSTGRES_DB || 'not-set',
      POSTGRES_USER: process.env.POSTGRES_USER || 'not-set'
    },
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.version
  };
  
  res.json(frontendInfo);
});

// Backend connectivity test
app.get('/api/backend-status', async (req, res) => {
  try {
    const startTime = Date.now();
    
    // Test database connection
    const result = await pool.query('SELECT NOW() as current_time, version() as db_version');
    const endTime = Date.now();
    
    // Get recent health checks
    const healthChecks = await pool.query(
      'SELECT * FROM health_checks ORDER BY timestamp DESC LIMIT 10'
    );
    
    // Get database stats
    const dbStats = await pool.query(`
      SELECT 
        pg_database_size(current_database()) as db_size,
        (SELECT count(*) FROM health_checks) as total_health_checks
    `);
    
    const backendInfo = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: {
        connected: true,
        responseTime: `${endTime - startTime}ms`,
        currentTime: result.rows[0].current_time,
        version: result.rows[0].db_version,
        size: dbStats.rows[0].db_size,
        totalHealthChecks: parseInt(dbStats.rows[0].total_health_checks)
      },
      recentHealthChecks: healthChecks.rows,
      connectionPool: {
        totalCount: pool.totalCount,
        idleCount: pool.idleCount,
        waitingCount: pool.waitingCount
      }
    };
    
    // Log health check
    await pool.query(
      'INSERT INTO health_checks (status, message) VALUES ($1, $2)',
      ['success', `API health check - Response time: ${endTime - startTime}ms`]
    );
    
    res.json(backendInfo);
  } catch (error) {
    console.error('Backend status error:', error);
    
    const backendInfo = {
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
      database: {
        connected: false,
        error: error.message
      }
    };
    
    res.status(500).json(backendInfo);
  }
});

// System info API
app.get('/api/system-info', async (req, res) => {
  try {
    const systemInfo = {
      kubernetes: {
        podName: process.env.HOSTNAME,
        namespace: process.env.POD_NAMESPACE,
        nodeName: process.env.NODE_NAME,
        podIP: process.env.POD_IP,
        serviceAccount: process.env.SERVICE_ACCOUNT
      },
      application: {
        name: 'terrahelm-webapp',
        version: '1.0.0',
        uptime: process.uptime(),
        startTime: new Date(Date.now() - process.uptime() * 1000).toISOString()
      },
      system: {
        platform: process.platform,
        arch: process.arch,
        nodeVersion: process.version,
        memory: process.memoryUsage(),
        cpuUsage: process.cpuUsage()
      }
    };
    
    res.json(systemInfo);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ status: 'unhealthy', error: error.message });
  }
});

// Test database write
app.post('/api/test-write', async (req, res) => {
  try {
    const { message } = req.body;
    const result = await pool.query(
      'INSERT INTO health_checks (status, message) VALUES ($1, $2) RETURNING *',
      ['manual-test', message || 'Manual test from web interface']
    );
    
    res.json({
      success: true,
      message: 'Data written successfully',
      data: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// Initialize and start server
async function startServer() {
  try {
    await initDatabase();
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Terrahelm webapp running on port ${PORT}`);
      console.log(`Frontend: http://localhost:${PORT}`);
      console.log(`Health: http://localhost:${PORT}/health`);
      console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  await pool.end();
  process.exit(0);
});

startServer();