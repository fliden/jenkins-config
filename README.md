# Personal Jenkins Instance - Docker + JCasC

This repository contains a fully version-controlled Jenkins deployment using Docker Compose and Jenkins Configuration as Code (JCasC).

## Prerequisites

- A Linux server (DigitalOcean Droplet or similar)
- Docker Engine installed
- Docker Compose installed
- Git installed

## Deployment Instructions

### 1. Install Docker and Docker Compose (if not already installed)

```bash
# Update system packages
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get install docker-compose-plugin -y

# Add your user to the docker group (optional, for non-root usage)
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clone This Repository

```bash
git clone <your-repo-url>
cd jenkins-config
```

### 3. Configure Docker Socket Permissions

Find your host's Docker group ID:

```bash
getent group docker | cut -d: -f3
```

Edit `docker-compose.yml` and replace `999` in the `group_add` section with the actual GID from above.

### 4. Build and Launch Jenkins

```bash
# Build the custom Jenkins image
docker-compose build

# Start Jenkins in detached mode
docker-compose up -d

# View logs (optional)
docker-compose logs -f
```

### 5. Access Jenkins

1. Open your browser and navigate to: `http://<your-server-ip>:8080`
2. Login with the default credentials:
   - **Username:** `admin`
   - **Password:** `changeme`

### 6. Post-Deployment Security

**IMPORTANT:** Change the admin password immediately after first login!

1. Go to: **Manage Jenkins** → **Manage Users** → Click on **admin** → **Configure**
2. Set a strong password
3. Update `jenkins.yaml` with the new password (for future rebuilds)
4. Consider setting up:
   - Firewall rules (UFW or DigitalOcean Firewall)
   - SSL/TLS with Nginx reverse proxy
   - SSH key-based authentication for the server

## Management Commands

```bash
# Stop Jenkins
docker-compose down

# Restart Jenkins
docker-compose restart

# View logs
docker-compose logs -f jenkins

# Rebuild after configuration changes
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Configuration Files

- **plugins.txt**: List of Jenkins plugins to install
- **Dockerfile**: Custom Jenkins image with pre-installed plugins
- **jenkins.yaml**: JCasC configuration (users, security, system settings)
- **docker-compose.yml**: Container orchestration and volume management

## Data Persistence

Jenkins data is stored in the `jenkins_home` Docker volume. To backup:

```bash
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar czf /backup/jenkins-backup-$(date +%Y%m%d).tar.gz /data
```

To restore:

```bash
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar xzf /backup/jenkins-backup-YYYYMMDD.tar.gz
```

## Troubleshooting

### Docker Socket Permission Denied

If Jenkins can't access Docker, verify:
1. The `group_add` GID matches your host's Docker group
2. The Docker socket is mounted correctly
3. Restart Jenkins: `docker-compose restart`

### Jenkins Won't Start

Check logs: `docker-compose logs jenkins`

Common issues:
- Port 8080 already in use
- Insufficient disk space
- Corrupted `jenkins_home` volume

## License

MIT
