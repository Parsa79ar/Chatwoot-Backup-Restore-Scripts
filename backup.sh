#!/bin/bash

# Enhanced Chatwoot Backup Script with Health Checks
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="/backups/chatwoot_$timestamp"
mkdir -p $backup_dir

echo "=== Starting Chatwoot Backup ==="
echo "Source directory: /home/chatwoot"

# Health check: Ensure containers are running
echo "Checking container health..."
if ! docker ps --filter "name=chatwoot-postgres-1" --filter "status=running" | grep -q chatwoot-postgres-1; then
    echo "ERROR: PostgreSQL container is not running!"
    exit 1
fi

if ! docker ps --filter "name=chatwoot-redis-1" --filter "status=running" | grep -q chatwoot-redis-1; then
    echo "ERROR: Redis container is not running!"
    exit 1
fi

if ! docker ps --filter "name=chatwoot-rails-1" --filter "status=running" | grep -q chatwoot-rails-1; then
    echo "ERROR: Rails container is not running!"
    exit 1
fi

# Optional: Check for pending migrations
echo "Checking for pending migrations..."
pending_migrations=$(docker exec chatwoot-rails-1 bundle exec rails db:migrate:status 2>/dev/null | grep -c "down" || echo "0")
if [ "$pending_migrations" -gt 0 ]; then
    echo "WARNING: $pending_migrations pending migrations found. Consider running migrations before backup."
    echo "Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Backup cancelled."
        exit 1
    fi
fi

# 1. Backup PostgreSQL
echo "Backing up database..."
docker exec chatwoot-postgres-1 pg_dumpall -U postgres > $backup_dir/chatwoot_db.sql
if [ $? -ne 0 ]; then
    echo "ERROR: Database backup failed!"
    exit 1
fi

# 2. Backup Redis
echo "Backing up Redis..."
docker exec chatwoot-redis-1 redis-cli save
docker cp chatwoot-redis-1:/data/dump.rdb $backup_dir/redis.rdb
if [ $? -ne 0 ]; then
    echo "ERROR: Redis backup failed!"
    exit 1
fi

# 3. Backup all host files (including .env and compose file)
echo "Backing up host files..."
cp -r /home/chatwoot/.env /home/chatwoot/docker-compose.yaml /home/chatwoot/data $backup_dir/
if [ $? -ne 0 ]; then
    echo "ERROR: Host files backup failed!"
    exit 1
fi

# 4. Backup container storage
echo "Backing up uploads..."
docker cp chatwoot-rails-1:/app/storage $backup_dir/
if [ $? -ne 0 ]; then
    echo "ERROR: Storage backup failed!"
    exit 1
fi

# 5. Create archive
echo "Compressing backup..."
tar czf /backups/chatwoot_backup_$timestamp.tar.gz -C $backup_dir .
if [ $? -ne 0 ]; then
    echo "ERROR: Compression failed!"
    exit 1
fi

# 6. Verify and cleanup
echo "Verifying backup..."
tar tzf /backups/chatwoot_backup_$timestamp.tar.gz > /dev/null || { echo "Backup verification failed!"; exit 1; }
rm -rf $backup_dir

echo "=== Backup Complete ==="
echo "Backup saved to: /backups/chatwoot_backup_$timestamp.tar.gz"
echo "Size: $(du -sh /backups/chatwoot_backup_$timestamp.tar.gz | cut -f1)"