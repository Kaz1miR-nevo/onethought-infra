# Redis Usage Guide

## 📋 Overview

Redis is used for:
- **Caching** (optional, foundation for future features)
- **Rate limiting** (distributed rate limiting across instances)
- **Session storage** (future)

## 🏗️ Architecture

### Separation Strategy

We use **separate Redis database indexes** to isolate stage and production:

- **Stage**: Redis DB `0` (default)
- **Production**: Redis DB `1`

This is simpler and safer than key prefixes for our use case.

### Alternative: Key Prefixes

If you prefer key prefixes instead, set:
```bash
REDIS_PREFIX=stage:  # In stage.api.env
REDIS_PREFIX=prod:   # In prod.api.env
```

And unset `REDIS_DB` (or set to `0` for both).

## 🔧 Configuration

### Redis Container Settings

**Stage** (`docker-compose.stage.yml`):
```yaml
redis:
  command: >
    redis-server
    --maxmemory 256mb
    --maxmemory-policy allkeys-lru
```

**Production** (`docker-compose.prod.yml`):
```yaml
redis:
  command: >
    redis-server
    --maxmemory 512mb
    --maxmemory-policy allkeys-lru
```

### Memory Limits

- **Stage**: 256 MB (sufficient for testing)
- **Production**: 512 MB (can be increased if needed)

### Eviction Policy

`allkeys-lru` (Least Recently Used):
- Evicts least recently used keys when memory limit is reached
- Suitable for caching use case
- No persistence (data can be lost on restart, which is OK for cache)

## 🔌 Connection

### From API Container

Redis is accessible via Docker network:
```bash
REDIS_URL=redis://redis:6379
REDIS_DB=0  # Stage
REDIS_DB=1  # Production
```

### Security

- **NOT exposed to public internet**
- Only accessible from containers in the same Docker network
- No password required (internal network only)

## 💻 Usage in Code

### API Integration

Redis is **optional** - the API works without it. If `REDIS_URL` is not set, Redis features are disabled.

### Example: Rate Limiting

```typescript
import { authRateLimit } from './middleware/rate-limit-redis.js';

// Apply to auth routes
app.post('/api/v1/auth/login', {
  preHandler: [authRateLimit],
}, loginHandler);
```

### Example: Caching

```typescript
import { getRedis, setRedis } from './lib/redis.js';

// Get from cache
const cached = await getRedis('user:123');
if (cached) {
  return JSON.parse(cached);
}

// Fetch and cache
const data = await fetchData();
await setRedis('user:123', JSON.stringify(data), 3600); // 1 hour TTL
```

## 🛠️ Operations

### Connect to Redis CLI

**Stage**:
```bash
docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli
```

**Production**:
```bash
docker compose -p onethought_prod -f docker-compose.prod.yml exec redis redis-cli
```

### Select Database

```bash
# In redis-cli
SELECT 0  # Stage
SELECT 1  # Production
```

### Common Commands

```bash
# List all keys
KEYS *

# Get value
GET rate_limit:192.168.1.1

# Set value with TTL
SETEX mykey 3600 "value"

# Delete key
DEL mykey

# Clear current database
FLUSHDB

# Get memory info
INFO memory

# Monitor commands in real-time
MONITOR
```

### Check Memory Usage

```bash
docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli INFO memory
```

### Clear Cache (if needed)

```bash
# Stage
docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli FLUSHDB

# Production (⚠️ be careful!)
docker compose -p onethought_prod -f docker-compose.prod.yml exec redis redis-cli -n 1 FLUSHDB
```

## 📊 Monitoring

### Health Check

Redis containers have health checks:
```bash
docker compose -p onethought_stage -f docker-compose.stage.yml ps redis
# Should show "healthy"
```

### Logs

```bash
docker compose -p onethought_stage -f docker-compose.stage.yml logs redis
```

### Metrics

```bash
# Memory usage
docker stats onethought_stage_redis

# Redis info
docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli INFO
```

## 🔍 Troubleshooting

### Redis Not Connecting

1. **Check container is running**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml ps redis
   ```

2. **Check network**
   ```bash
   docker network inspect onethought_stage_network
   ```

3. **Test connection from API container**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml exec api sh
   # Inside container:
   wget -O- http://redis:6379  # Should fail (not HTTP), but confirms network
   ```

### High Memory Usage

1. **Check current usage**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli INFO memory
   ```

2. **Clear old keys** (if safe)
   ```bash
   # Find keys with TTL
   docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli --scan --pattern "rate_limit:*"
   ```

3. **Increase memory limit** (if needed)
   - Edit `docker-compose.stage.yml` or `docker-compose.prod.yml`
   - Update `--maxmemory` value
   - Restart container

### Performance Issues

1. **Check connection count**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli INFO clients
   ```

2. **Monitor slow commands**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli SLOWLOG GET 10
   ```

## 🚀 Future Enhancements

Potential uses for Redis:
- **Session storage** (user sessions)
- **Real-time features** (pub/sub for notifications)
- **Leaderboards** (sorted sets)
- **Queue system** (for background jobs)

## 📚 References

- [Redis Documentation](https://redis.io/docs/)
- [Redis Commands](https://redis.io/commands/)
- [Redis Configuration](https://redis.io/docs/management/config/)






