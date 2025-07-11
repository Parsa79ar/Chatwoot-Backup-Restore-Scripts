# Chatwoot Backup & Restore Scripts

A complete backup and restore solution for Chatwoot deployments running on Docker Compose.

## Overview

This repository contains two bash scripts that provide comprehensive backup and restore functionality for Chatwoot installations:

- **`backup.sh`** - Creates full backups of your Chatwoot instance
- **`restore.sh`** - Restores Chatwoot from backup files

## Features

### Backup Script (`backup.sh`)
- PostgreSQL database backup using `pg_dumpall`
- Redis data backup with automatic save
- Host configuration files (`.env`, `docker-compose.yaml`)
- Application data and uploads
- Compressed archive creation with timestamp
- Backup verification and cleanup

### Restore Script (`restore.sh`)
- Full system restoration from backup archive
- Automatic dependency installation (Docker, Docker Compose)
- Database and Redis restoration
- File uploads and storage restoration
- Proper permissions and ownership setup

## Prerequisites

- Ubuntu/Debian-based system
- Docker and Docker Compose (will be installed by restore script if missing)
- Chatwoot deployed using Docker Compose
- Root or sudo privileges

## Installation

1. Clone this repository:
```bash
git clone https://github.com/Parsa79ar/Chatwoot-Backup-Restore-Scripts.git
cd Chatwoot-Backup-Restore-Scripts
```

2. Make scripts executable:
```bash
chmod +x backup.sh restore.sh
```

3. Create backup directory:
```bash
mkdir -p /backups
```

## Usage

### Creating a Backup

Run the backup script as root:

```bash
sudo ./backup.sh
```

The script will:
- Create a timestamped backup in `/backups/`
- Include all necessary data (database, Redis, files, configuration)
- Compress the backup into a `.tar.gz` file
- Verify the backup integrity
- Display backup location and size

**Example output:**
```
=== Starting Chatwoot Backup ===
Source directory: /home/chatwoot
Backing up database...
Backing up Redis...
Backing up host files...
Backing up uploads...
Compressing backup...
Verifying backup...
=== Backup Complete ===
Backup saved to: /backups/chatwoot_backup_20240115_143022.tar.gz
Size: 2.3G
```

### Restoring from Backup

Run the restore script with the backup file path:

```bash
sudo ./restore.sh /path/to/backup.tar.gz
```

**Example:**
```bash
sudo ./restore.sh /backups/chatwoot_backup_20240115_143022.tar.gz
```

The script will:
- Extract and verify the backup
- Install required dependencies
- Restore all data and configuration
- Start the Chatwoot services
- Provide access information

**Post-restore steps:**
1. Monitor startup: `docker-compose logs -f`
2. Check service status: `docker-compose ps`
3. Access Chatwoot at: `http://your-server-ip:3000`

## Backup Contents

Each backup includes:

- **Database**: Complete PostgreSQL dump with all tables and data
- **Redis**: Redis database file (`dump.rdb`)
- **Configuration**: Environment variables (`.env`) and Docker Compose file
- **Data**: Application data directory
- **Uploads**: User uploads and file storage

## Directory Structure

```
/home/chatwoot/           # Chatwoot installation directory
├── .env                  # Environment configuration
├── docker-compose.yaml   # Docker Compose configuration
└── data/                 # Application data

/backups/                 # Backup storage location
├── chatwoot_backup_YYYYMMDD_HHMMSS.tar.gz
└── ...
```

## Important Notes

### Before Backup
- Ensure Chatwoot is running and accessible
- Verify sufficient disk space in `/backups/`
- Consider stopping high-traffic operations during backup

### Before Restore
- **Warning**: Restore will overwrite existing Chatwoot installation
- Ensure the target server meets system requirements
- Back up any existing data before restoration
- Verify the backup file integrity

### Security Considerations
- Backup files contain sensitive data (database, configurations)
- Store backups in secure locations
- Consider encryption for sensitive environments
- Regularly test restore procedures

## Troubleshooting

### Common Issues

**Backup fails with "docker command not found"**
- Ensure Docker is installed and running
- Check if user has Docker permissions

**Restore fails with "Permission denied"**
- Run scripts with sudo privileges
- Ensure proper ownership of `/home/chatwoot`

**Database restore fails**
- Check PostgreSQL container logs: `docker logs chatwoot-postgres-1`
- Verify backup file integrity
- Ensure sufficient disk space

**Services don't start after restore**
- Check Docker Compose logs: `docker-compose logs`
- Verify all containers are running: `docker-compose ps`
- Check system resources (CPU, memory, disk)

### Log Analysis

Monitor the restoration process:
```bash
# Check all services
docker-compose ps

# View logs
docker-compose logs -f

# Check specific service
docker-compose logs chatwoot-rails-1
```

## Automation

### Scheduled Backups

Create a cron job for automated backups:

```bash
# Edit crontab
sudo crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/backup.sh

# Add weekly backup cleanup (keep last 4 weeks)
0 3 * * 0 find /backups -name "chatwoot_backup_*.tar.gz" -mtime +28 -delete
```

### Backup Rotation

Implement backup rotation to manage disk space:

```bash
# Keep last 7 daily backups
find /backups -name "chatwoot_backup_*.tar.gz" -mtime +7 -delete
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Chatwoot documentation
- Open an issue in this repository

---

**⚠️ Important**: Always test backup and restore procedures in a development environment before using in production.