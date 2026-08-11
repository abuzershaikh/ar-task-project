# VPS Requirements for Task Engine Backend

## Executive Summary

**Recommended VPS Configuration:**
- **CPU**: 4 vCPU cores (minimum 2 cores)
- **RAM**: 8 GB (minimum 4 GB)
- **Storage**: 40 GB SSD (minimum 25 GB)
- **Bandwidth**: 2 TB/month
- **OS**: Ubuntu 22.04 LTS or similar Linux distribution

---

## 📊 Current Codebase Analysis

### Source Code Size
- **Total Files**: 32,845 files
- **Total Size**: 218 MB
- **Engine Modules**: 13 specialized engines
- **Architecture**: NestJS Modular Monolith

### Engine Breakdown
1. task-engine (Core task management)
2. matching-engine (Worker-task matching)
3. scoring-engine (Performance calculations)
4. ranking-engine (Worker ranking)
5. allocation-engine (Task assignment)
6. eligibility-engine (Worker eligibility)
7. reward-engine (Reward calculations)
8. review-engine (Submission reviews)
9. earning-engine (Earning calculations)
10. payout-engine (Withdrawal processing)
11. progress-engine (Progress tracking)
12. fraud-engine (Risk scoring)
13. notification-engine (Multi-channel notifications)

---

## 💾 Disk Space Requirements

### Production Deployment Breakdown

| Component | Size | Notes |
|-----------|------|-------|
| **Source Code** | 220 MB | NestJS app + 13 engines |
| **node_modules** | 180 MB | Production dependencies only (no devDependencies) |
| **Compiled dist/** | 50 MB | TypeScript compiled to JavaScript |
| **MySQL Database** | 5-10 GB | Initial allocation (grows with data) |
| **Redis** | 100-500 MB | Queue data, cache |
| **Logs** | 2 GB | Application logs (rotated) |
| **Backups** | 5 GB | Database backups (compressed) |
| **OS + System** | 8 GB | Ubuntu base + utilities |
| **Buffer/Growth** | 5 GB | Future growth |

### Total Storage Calculation

```
Minimum:  25 GB SSD  (tight, for testing)
Recommended: 40 GB SSD  (comfortable production)
Optimal: 80 GB SSD  (long-term with growth)
```

**Why SSD?**
- MySQL random read/write operations
- Fast log writing
- Redis persistence
- Better overall API response times

---

## 🧠 RAM Requirements

### Memory Consumption Analysis

| Component | Memory Usage | Notes |
|-----------|--------------|-------|
| **NestJS Application** | 512 MB - 1.5 GB | Base runtime with 13 engines |
| **MySQL Database** | 1-2 GB | InnoDB buffer pool + connections |
| **Redis (BullMQ)** | 256-512 MB | Queue jobs + cache |
| **Operating System** | 500 MB | Ubuntu kernel + services |
| **PM2 Process Manager** | 100 MB | Process monitoring |
| **Buffer for Peaks** | 1-2 GB | Traffic spikes, matching calculations |

### RAM Calculation by Load

**Low Traffic (100 concurrent users)**
```
NestJS:  800 MB
MySQL:   1 GB
Redis:   256 MB
OS:      500 MB
Buffer:  1 GB
-----------------
Total:   3.5 GB → Recommend 4 GB RAM
```

**Medium Traffic (500-1000 concurrent users)**
```
NestJS:  1.2 GB
MySQL:   1.5 GB
Redis:   400 MB
OS:      500 MB
Buffer:  1.5 GB
-----------------
Total:   5.1 GB → Recommend 8 GB RAM
```

**High Traffic (2000+ concurrent users)**
```
NestJS:  2 GB
MySQL:   3 GB
Redis:   512 MB
OS:      500 MB
Buffer:  2 GB
-----------------
Total:   8 GB → Recommend 16 GB RAM
```

### Recommended Configuration

```
Minimum:  4 GB RAM   (up to 500 users, basic operations)
Recommended: 8 GB RAM   (1000+ users, comfortable production)
Optimal: 16 GB RAM  (2000+ users, high performance)
```

---

## ⚙️ CPU Requirements

### CPU-Intensive Operations

1. **Matching Engine**
   - Filters workers by location, KYC, capacity
   - Can process 500+ workers per matching cycle
   - CPU-bound calculations

2. **Scoring Engine**
   - Calculates performance scores for all workers
   - Complex algorithms with historical data

3. **Ranking Engine**
   - Sorts and ranks workers by multiple criteria
   - Real-time recalculations

4. **Background Jobs (BullMQ)**
   - Task assignments
   - Notification sending
   - Reward calculations
   - Report generation

5. **API Request Processing**
   - JSON parsing/serialization
   - Database queries (MySQL)
   - Authentication/JWT validation

### CPU Core Calculation

**Single Core Performance:**
- Can handle ~50-100 requests/second
- Background jobs will compete with API requests

**Multi-Core Benefits:**
- NestJS is multi-threaded (Node.js worker threads)
- MySQL can use multiple cores
- BullMQ workers run in parallel
- Operating system overhead

### Recommended CPU Configuration

```
Minimum:  2 vCPU cores  (testing, low traffic)
   - Can handle 500 concurrent users
   - 100 requests/second
   - Basic background processing

Recommended: 4 vCPU cores  (production)
   - Can handle 1500 concurrent users
   - 300+ requests/second
   - Smooth background job processing
   - Matching engine calculations
   - Database query optimization

Optimal: 8 vCPU cores  (high performance)
   - 3000+ concurrent users
   - 500+ requests/second
   - Heavy background processing
   - Complex matching scenarios
   - Multiple engine operations in parallel
```

---

## 📡 Network & Bandwidth

### Traffic Estimation

**Per API Request:**
- Average request size: 2-5 KB
- Average response size: 10-50 KB (depending on endpoint)
- Worker task list: ~100 KB (with images)
- Buyer dashboard: ~200 KB

**Monthly Bandwidth Calculation:**

**Low Traffic (500 users/day, 10 requests each)**
```
500 users × 10 requests × 50 KB × 30 days = 7.5 GB/month
```

**Medium Traffic (2000 users/day, 20 requests each)**
```
2000 users × 20 requests × 50 KB × 30 days = 60 GB/month
```

**High Traffic (5000 users/day, 30 requests each)**
```
5000 users × 30 requests × 50 KB × 30 days = 225 GB/month
```

### Recommended Bandwidth

```
Minimum:  500 GB/month  (small scale)
Recommended: 1-2 TB/month  (production)
Optimal: 3-5 TB/month  (high growth)
```

**Note:** Most VPS providers offer unmetered or high bandwidth (2-5 TB) by default.

---

## 🎯 VPS Provider Recommendations

### Tier 1: Development/Testing

**DigitalOcean Droplet - $24/month**
- 2 vCPU
- 4 GB RAM
- 80 GB SSD
- 4 TB bandwidth

**Linode Shared - $24/month**
- 2 CPU
- 4 GB RAM
- 80 GB SSD
- 4 TB bandwidth

### Tier 2: Production (Recommended)

**DigitalOcean Droplet - $48/month**
- 4 vCPU
- 8 GB RAM
- 160 GB SSD
- 5 TB bandwidth

**Vultr High Frequency - $48/month**
- 4 vCPU
- 8 GB RAM
- 180 GB SSD
- 4 TB bandwidth

**AWS Lightsail - $40/month**
- 2 vCPU
- 4 GB RAM
- 80 GB SSD
- 4 TB bandwidth

**Hetzner Cloud - €22.39/month (~$24)**
- 4 vCPU (AMD/Intel)
- 8 GB RAM
- 160 GB SSD
- 20 TB bandwidth
- **Best Value!**

### Tier 3: High Performance

**DigitalOcean Droplet - $96/month**
- 8 vCPU
- 16 GB RAM
- 320 GB SSD
- 6 TB bandwidth

**AWS EC2 t3.xlarge - ~$120/month**
- 4 vCPU
- 16 GB RAM
- EBS storage separate
- Pay-as-you-go bandwidth

---

## 🔧 Software Requirements

### Required Services

```bash
# Operating System
Ubuntu 22.04 LTS (Recommended)
# or
Debian 12
# or
CentOS Stream 9

# Runtime
Node.js 18.x or 20.x LTS
npm 9.x or later

# Database
MySQL 8.0+ (with InnoDB engine)
# Initial allocation: 5-10 GB

# Cache/Queue
Redis 7.x (for BullMQ)
# Memory: 256-512 MB

# Process Manager
PM2 (for Node.js process management)

# Web Server (optional, for SSL/proxy)
Nginx 1.24+ or Caddy 2.x

# Monitoring (optional but recommended)
PM2 Plus or New Relic
```

### Installation Space Requirements

```
Node.js:     ~50 MB
MySQL:       ~500 MB
Redis:       ~30 MB
Nginx:       ~10 MB
PM2:         ~50 MB
-----------------------
Total:       ~640 MB (included in OS allocation)
```

---

## 📈 Growth & Scaling Projections

### Year 1 (0-5000 active users)
- **VPS**: 4 vCPU, 8 GB RAM, 40 GB SSD
- **Database**: 5-15 GB
- **Monthly Cost**: $40-50

### Year 2 (5000-20,000 active users)
- **VPS**: 8 vCPU, 16 GB RAM, 80 GB SSD
- **Database**: 15-50 GB
- **Monthly Cost**: $90-120
- **Consider**: Separate database server

### Year 3+ (20,000+ active users)
- **App Server**: 8 vCPU, 16 GB RAM
- **Database Server**: 4 vCPU, 16 GB RAM, 200 GB SSD
- **Redis Server**: 2 vCPU, 4 GB RAM
- **Monthly Cost**: $200-300
- **Architecture**: Multi-server setup

---

## 🚀 Deployment Checklist

### Pre-Deployment

- [ ] VPS provisioned (Ubuntu 22.04 LTS)
- [ ] SSH key authentication configured
- [ ] Firewall configured (UFW)
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 3000 (App, internal)
  - Port 3306 (MySQL, internal only)
  - Port 6379 (Redis, internal only)
- [ ] Non-root user created with sudo access

### Software Installation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install MySQL 8.0
sudo apt install -y mysql-server
sudo mysql_secure_installation

# Install Redis
sudo apt install -y redis-server
sudo systemctl enable redis-server

# Install PM2
sudo npm install -g pm2
pm2 startup

# Install Nginx (optional)
sudo apt install -y nginx
sudo systemctl enable nginx
```

### Application Deployment

```bash
# Clone repository
git clone <your-repo-url> /var/www/task-engine
cd /var/www/task-engine

# Install dependencies (production only)
npm ci --production

# Create .env file
cp .env.example .env
nano .env  # Configure database, JWT secrets, etc.

# Build application
npm run build

# Start with PM2
pm2 start dist/main.js --name task-engine -i 2
pm2 save

# Setup log rotation
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 100M
pm2 set pm2-logrotate:retain 10
```

### Database Setup

```bash
# Login to MySQL
sudo mysql -u root -p

# Create database and user
CREATE DATABASE task_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'taskapp'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON task_platform.* TO 'taskapp'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Run migrations
npm run migration:run
```

### Post-Deployment

- [ ] Application running on PM2
- [ ] Database migrations applied
- [ ] Redis connected and working
- [ ] Nginx reverse proxy configured (if using)
- [ ] SSL certificate installed (Let's Encrypt)
- [ ] Environment variables secure
- [ ] Monitoring enabled (PM2 Plus or similar)
- [ ] Backup strategy implemented
- [ ] Log rotation configured

---

## 🔒 Security Considerations

### Firewall Rules
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### MySQL Security
- Bind to localhost only: `bind-address = 127.0.0.1`
- Strong passwords for all database users
- Regular backups with `mysqldump`

### Redis Security
- Bind to localhost: `bind 127.0.0.1`
- Set password: `requirepass your_strong_password`
- Disable dangerous commands

### Application Security
- Environment variables in `.env` (never commit)
- JWT secrets (minimum 32 characters, random)
- Rate limiting enabled on API
- CORS properly configured
- Helmet.js for security headers

---

## 📊 Monitoring & Maintenance

### Resource Monitoring

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Application logs
pm2 logs task-engine

# MySQL performance
sudo mysqladmin -u root -p status

# Redis info
redis-cli INFO
```

### Recommended Monitoring Tools

1. **PM2 Plus** (Free tier available)
   - Real-time application monitoring
   - Error tracking
   - Performance metrics

2. **Netdata** (Open source)
   - System metrics
   - Real-time dashboards
   - Alerts

3. **Prometheus + Grafana** (Advanced)
   - Custom metrics
   - Beautiful dashboards
   - Alerting

### Backup Strategy

```bash
# Automated daily MySQL backups
0 2 * * * /usr/bin/mysqldump -u root -p'password' task_platform | gzip > /backup/db-$(date +\%Y\%m\%d).sql.gz

# Keep last 7 days
find /backup -name "db-*.sql.gz" -mtime +7 -delete
```

---

## 💰 Cost Summary

### Minimum Setup (Testing/Development)
- VPS: $12-15/month (2 vCPU, 2 GB RAM)
- Domain: $10-15/year
- **Total**: ~$13-16/month

### Recommended Setup (Production)
- VPS: $40-50/month (4 vCPU, 8 GB RAM)
- Domain: $10-15/year
- SSL: Free (Let's Encrypt)
- Backup Storage: $5/month (optional)
- Monitoring: Free-$10/month
- **Total**: ~$45-65/month

### High Performance Setup
- VPS: $90-120/month (8 vCPU, 16 GB RAM)
- Domain: $10-15/year
- Managed Database: $15-30/month (optional)
- CDN: $0-20/month (optional)
- **Total**: ~$105-170/month

---

## 🎯 Final Recommendations

### For Initial Launch (0-1000 users)

**DigitalOcean or Hetzner**
- 4 vCPU
- 8 GB RAM
- 80-160 GB SSD
- $40-48/month

**Rationale:**
- Room for growth
- Smooth performance
- Can handle traffic spikes
- Cost-effective

### For Scaling (1000-5000 users)

**Same server, optimize:**
- Enable MySQL query caching
- Redis for API response caching
- PM2 cluster mode (multiple instances)
- Nginx load balancing

### For Enterprise (5000+ users)

**Multi-server architecture:**
1. App Server (8 vCPU, 16 GB) - $90/month
2. Database Server (4 vCPU, 16 GB) - $80/month
3. Redis/Cache Server (2 vCPU, 4 GB) - $24/month
4. Load Balancer - $10-20/month
**Total**: ~$200-220/month

---

## 📞 Quick Reference

| Metric | Minimum | Recommended | Optimal |
|--------|---------|-------------|---------|
| **CPU** | 2 cores | 4 cores | 8 cores |
| **RAM** | 4 GB | 8 GB | 16 GB |
| **Storage** | 25 GB SSD | 40 GB SSD | 80 GB SSD |
| **Bandwidth** | 500 GB | 2 TB | 5 TB |
| **Users** | 500 | 1500 | 3000+ |
| **Cost/month** | $15 | $48 | $96 |

**Start with Recommended (4 vCPU, 8 GB RAM, 40 GB SSD) for best balance of performance and cost.**
