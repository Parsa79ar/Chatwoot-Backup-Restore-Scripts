#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/backup.tar.gz"
  exit 1
fi

echo "=== Preparing Chatwoot Restore ==="
backup_file=$1
restore_dir="/tmp/chatwoot_restore_$(date +%s)"
mkdir -p $restore_dir

# Verify backup
echo "Verifying backup..."
tar tzf "$backup_file" > /dev/null || { echo "Invalid backup file!"; exit 1; }

# Extract backup
echo "Extracting backup..."
tar xzf "$backup_file" -C "$restore_dir"

# Install prerequisites
echo "Installing dependencies..."
apt update && apt install -y docker.io docker-compose

# Setup directory structure
echo "Creating chatwoot home..."
mkdir -p /home/chatwoot
chown -R 1000:1000 /home/chatwoot

# Restore host files
echo "Restoring configuration..."
cp "$restore_dir"/.env "$restore_dir"/docker-compose.yaml /home/chatwoot/
cp -r "$restore_dir"/data /home/chatwoot/

# Start containers
echo "Launching Chatwoot..."
cd /home/chatwoot
docker-compose up -d

# Restore database
echo "Restoring database (this may take several minutes)..."
docker cp "$restore_dir"/chatwoot_db.sql chatwoot-postgres-1:/tmp/
docker exec chatwoot-postgres-1 psql -U postgres -f /tmp/chatwoot_db.sql

# Restore Redis
echo "Restoring Redis..."
docker cp "$restore_dir"/redis.rdb chatwoot-redis-1:/data/dump.rdb
docker restart chatwoot-redis-1

# Restore storage
echo "Restoring uploads..."
docker cp "$restore_dir"/storage/ chatwoot-rails-1:/app/

# Cleanup
rm -rf "$restore_dir"

echo "=== Restore Complete ==="
echo "1. Monitor startup with: docker-compose logs -f"
echo "2. Check service status: docker-compose ps"
echo "3. Access Chatwoot at: http://your-server-ip:3000"