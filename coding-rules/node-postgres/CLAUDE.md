# Node.js PostgreSQL - Coding Rules for Claude Code

This file provides specific guidance for Claude Code when working with Node.js applications using PostgreSQL.

## Project Setup & Commands

### Initial Setup
```bash
# Install dependencies
npm install
# or
yarn install

# Setup environment
cp .env.example .env

# Database setup
npm run db:migrate
npm run db:seed
```

### Development Commands
```bash
# Start development server
npm run dev
# or
npm run start:dev

# Run tests
npm test
npm run test:watch
npm run test:coverage

# Code quality
npm run lint
npm run lint:fix
npm run type-check

# Database operations
npm run db:migrate
npm run db:rollback
npm run db:reset
```

## Architecture Guidelines

### Directory Structure
```
src/
├── controllers/    # Route handlers
├── services/       # Business logic
├── models/         # Database models
├── middlewares/    # Express middlewares
├── routes/         # Route definitions
├── db/
│   ├── migrations/ # Database migrations
│   ├── seeds/      # Seed data
│   └── queries/    # Complex SQL queries
├── utils/          # Helper functions
└── types/          # TypeScript types
```

### Database Connection Pattern

```javascript
// db/connection.js
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
};
```

### Query Patterns

#### 1. Parameterized Queries (Always use these)
```javascript
// Good - prevents SQL injection
const result = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// Bad - vulnerable to SQL injection
const result = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

#### 2. Transaction Pattern
```javascript
const client = await db.getClient();
try {
  await client.query('BEGIN');
  
  const orderResult = await client.query(
    'INSERT INTO orders (user_id, total) VALUES ($1, $2) RETURNING id',
    [userId, total]
  );
  
  await client.query(
    'INSERT INTO order_items (order_id, product_id, quantity) VALUES ($1, $2, $3)',
    [orderResult.rows[0].id, productId, quantity]
  );
  
  await client.query('COMMIT');
} catch (e) {
  await client.query('ROLLBACK');
  throw e;
} finally {
  client.release();
}
```

### API Design Patterns

#### 1. Error Handling Middleware
```javascript
// middleware/errorHandler.js
const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  
  if (err.code === '23505') { // Unique violation
    return res.status(409).json({
      error: 'Resource already exists',
      field: err.detail
    });
  }
  
  if (err.code === '23503') { // Foreign key violation
    return res.status(400).json({
      error: 'Invalid reference',
      field: err.detail
    });
  }
  
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  });
};
```

#### 2. Async Route Handler
```javascript
// utils/asyncHandler.js
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Usage in routes
router.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id);
  res.json(user);
}));
```

### Migration Patterns

```javascript
// migrations/20240101_create_users.js
exports.up = async (db) => {
  await db.query(`
    CREATE TABLE users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE INDEX idx_users_email ON users(email);
  `);
};

exports.down = async (db) => {
  await db.query('DROP TABLE IF EXISTS users CASCADE');
};
```

### Security Best Practices

1. **Environment Variables**
   ```bash
   DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
   JWT_SECRET=your-secret-key
   NODE_ENV=development
   ```

2. **Input Validation**
   ```javascript
   const { body, validationResult } = require('express-validator');
   
   const validateUser = [
     body('email').isEmail().normalizeEmail(),
     body('password').isLength({ min: 8 }),
     (req, res, next) => {
       const errors = validationResult(req);
       if (!errors.isEmpty()) {
         return res.status(400).json({ errors: errors.array() });
       }
       next();
     }
   ];
   ```

3. **Authentication Middleware**
   ```javascript
   const jwt = require('jsonwebtoken');
   
   const authenticate = async (req, res, next) => {
     const token = req.headers.authorization?.split(' ')[1];
     
     if (!token) {
       return res.status(401).json({ error: 'No token provided' });
     }
     
     try {
       const decoded = jwt.verify(token, process.env.JWT_SECRET);
       req.userId = decoded.userId;
       next();
     } catch (error) {
       return res.status(401).json({ error: 'Invalid token' });
     }
   };
   ```

### Testing Patterns

#### 1. Database Testing
```javascript
// test/setup.js
beforeAll(async () => {
  await db.query('CREATE SCHEMA IF NOT EXISTS test');
  await db.migrate.latest();
});

afterAll(async () => {
  await db.query('DROP SCHEMA test CASCADE');
  await db.destroy();
});

beforeEach(async () => {
  await db.query('BEGIN');
});

afterEach(async () => {
  await db.query('ROLLBACK');
});
```

#### 2. API Testing
```javascript
const request = require('supertest');
const app = require('../src/app');

describe('POST /api/users', () => {
  it('should create a new user', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({
        email: 'test@example.com',
        password: 'password123'
      });
      
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.email).toBe('test@example.com');
  });
});
```

### Performance Optimization

1. **Connection Pooling**
   ```javascript
   // Configure pool size based on expected load
   const pool = new Pool({
     max: 20, // Maximum number of clients
     idleTimeoutMillis: 30000,
     connectionTimeoutMillis: 2000,
   });
   ```

2. **Query Optimization**
   ```javascript
   // Use EXPLAIN ANALYZE in development
   const explainQuery = async (query, params) => {
     const result = await db.query(`EXPLAIN ANALYZE ${query}`, params);
     console.log(result.rows);
   };
   ```

3. **Batch Operations**
   ```javascript
   // Use pg-format for bulk inserts
   const format = require('pg-format');
   
   const values = users.map(u => [u.name, u.email]);
   const query = format('INSERT INTO users (name, email) VALUES %L', values);
   await db.query(query);
   ```

### Common Pitfalls to Avoid

1. **Always handle connection errors**
2. **Use connection pooling, not individual connections**
3. **Always use parameterized queries**
4. **Handle PostgreSQL-specific errors properly**
5. **Don't forget to release clients in transactions**
6. **Index foreign keys and frequently queried columns**
7. **Use JSONB for flexible data, not JSON**
8. **Set appropriate pool sizes for production**

### Debugging Tools

```javascript
// Enable query logging in development
if (process.env.NODE_ENV === 'development') {
  const originalQuery = db.query;
  db.query = async (text, params) => {
    console.log('QUERY:', text);
    console.log('PARAMS:', params);
    const start = Date.now();
    const result = await originalQuery.call(db, text, params);
    const duration = Date.now() - start;
    console.log('DURATION:', duration, 'ms');
    return result;
  };
}
```

## DigitalOcean Deployment

### Droplet Setup & Deployment

```bash
# SSH into droplet
ssh root@[droplet-ip]

# Initial setup (one-time)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y postgresql postgresql-contrib
sudo npm install -g pm2

# Clone and setup application
git clone [repo-url] /var/www/app
cd /var/www/app
npm install --production

# Setup environment
cp .env.example .env
nano .env  # Configure with DigitalOcean credentials
```

### DigitalOcean Managed Database

```javascript
// db/connection.js for DO Managed PostgreSQL
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DO_DB_HOST,      // e.g., db-postgresql-nyc1-12345.b.db.ondigitalocean.com
  port: process.env.DO_DB_PORT,      // 25060 for managed databases
  database: process.env.DO_DB_NAME,
  user: process.env.DO_DB_USER,
  password: process.env.DO_DB_PASSWORD,
  ssl: {
    rejectUnauthorized: true,
    ca: process.env.DO_DB_CA_CERT   // DigitalOcean CA certificate
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### PM2 Process Management

```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'app-name',
    script: './src/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_file: './logs/pm2-combined.log',
    time: true,
    max_memory_restart: '1G',
    // Auto-restart on file changes
    watch: false,
    // Graceful shutdown
    kill_timeout: 5000,
    listen_timeout: 3000,
  }]
};
```

### Deployment Script

```bash
#!/bin/bash
# deploy.sh

# Pull latest code
git pull origin main

# Install dependencies
npm ci --production

# Run migrations
npm run db:migrate

# Reload PM2
pm2 reload ecosystem.config.js --update-env

# Clear application cache if needed
npm run cache:clear

echo "Deployment completed"
```

### Nginx Configuration

```nginx
# /etc/nginx/sites-available/app-name
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL with Let's Encrypt

```bash
# Install Certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo certbot renew --dry-run
```

### DigitalOcean Spaces (S3-compatible storage)

```javascript
// config/storage.js
const AWS = require('aws-sdk');

const spacesEndpoint = new AWS.Endpoint(process.env.DO_SPACES_ENDPOINT);
const s3 = new AWS.S3({
  endpoint: spacesEndpoint,
  accessKeyId: process.env.DO_SPACES_KEY,
  secretAccessKey: process.env.DO_SPACES_SECRET
});

// Upload file
const uploadFile = async (file, key) => {
  const params = {
    Bucket: process.env.DO_SPACES_BUCKET,
    Key: key,
    Body: file.buffer,
    ACL: 'public-read',
    ContentType: file.mimetype
  };
  
  return s3.upload(params).promise();
};
```

### Monitoring & Logs

```bash
# View PM2 logs
pm2 logs
pm2 monit

# System monitoring
htop
df -h
free -m

# PostgreSQL logs (Managed Database)
# Available in DigitalOcean control panel

# Application logs
tail -f /var/www/app/logs/app.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Backup Strategy

```bash
# Automated backups for Managed Database
# Configure in DigitalOcean control panel

# Application file backups to Spaces
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf backup_$DATE.tar.gz /var/www/app
s3cmd put backup_$DATE.tar.gz s3://your-backup-bucket/
```

### Performance Optimization

1. **Enable Node.js Cluster Mode**
   ```javascript
   // Already configured in PM2 ecosystem.config.js
   instances: 'max',
   exec_mode: 'cluster'
   ```

2. **Redis for Caching (DigitalOcean Managed Redis)**
   ```javascript
   const redis = require('redis');
   const client = redis.createClient({
     host: process.env.DO_REDIS_HOST,
     port: process.env.DO_REDIS_PORT,
     password: process.env.DO_REDIS_PASSWORD,
     tls: {}
   });
   ```

3. **CDN Integration**
   ```javascript
   // Use DigitalOcean Spaces CDN
   const getAssetUrl = (path) => {
     return `${process.env.DO_CDN_URL}/${path}`;
   };
   ```

### Security Hardening

```bash
# Firewall setup
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Fail2ban for SSH protection
sudo apt-get install fail2ban
sudo systemctl enable fail2ban

# Automatic security updates
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```