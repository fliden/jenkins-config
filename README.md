# Personal Jenkins - Docker (DooD) + JCasC + Caddy

This repository contains a production-ready, fully containerized Jenkins CI/CD server.

It is designed for low-cost VPS hosting (like DigitalOcean) and uses **Docker outside of Docker (DooD)** to spin up ephemeral build agents. It includes **Caddy** for automatic HTTPS and **Jenkins Configuration as Code (JCasC)** for version-controlled settings.

## 🏗 Architecture

* **Jenkins Controller:** Runs as a container. Has 1 executor available, but builds should use Docker agents to avoid overloading the controller.
* **Docker Agents:** The controller mounts the host's Docker socket (`/var/run/docker.sock`). When a pipeline runs, Jenkins spins up a temporary sibling container (e.g., Python, Node) on the host to execute the build.
* **Caddy:** Acts as a reverse proxy (configured in `Caddyfile`), handling Let's Encrypt SSL termination automatically.
* **JCasC:** All Jenkins configuration (users, views, security) is defined in `jenkins.yaml`.

**⚠️ Important:** Jenkins has `numExecutors: 1` to prevent build hangs, but you **must** configure your pipelines to use Docker agents. Jobs without an agent specification will run directly on the controller, which can cause performance issues.

## 📋 Prerequisites

1.  **A Linux Server:** A DigitalOcean Droplet (Docker on Ubuntu) is recommended.
2.  **Domain Name:** An `A Record` pointing to your server's IP (e.g., `jenkins.yourdomain.com`).
3.  **Swap Space (Critical):** If using a server with < 4GB RAM, you **must** enable swap or Jenkins will crash.

### ⚡ Quick Start: Enable Swap (DigitalOcean)
Run these commands on your Droplet before installing Jenkins:
```bash
sudo fallocate -l 2G /swapfile && \
sudo chmod 600 /swapfile && \
sudo mkswap /swapfile && \
sudo swapon /swapfile && \
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 🚀 Deployment Instructions

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd jenkins-config
```

### 2. Configure Secrets (.env)
We do not store passwords or domains in Git. Create your local environment file:

```bash
cp .env.example .env
nano .env
```

Fill in your details:

* **ADMIN_PASSWORD:** Set a strong password.
* **JENKINS_URL:** e.g., `https://jenkins.yourdomain.com/`
* **DOMAIN_NAME:** e.g., `jenkins.yourdomain.com`

### 3. Configure Docker Permissions
To allow Jenkins to spin up containers, it needs the Group ID (GID) of the host's Docker group.

Find the ID:

```bash
getent group docker | cut -d: -f3
# Output example: 999
```

Update `docker-compose.yml`: Ensure the `group_add:` section matches this number.

### 4. Build and Launch
Run the stack using Docker Compose V2:

```bash
docker compose up -d --build
```

### 5. Verify
Wait ~30-60 seconds for Jenkins to initialize **and for Caddy to obtain SSL certificates**.

* **Visit:** `https://jenkins.yourdomain.com`
* **Login:** `admin` / `<Password from .env>`

**Note:** First-time SSL certificate issuance may take 1-2 minutes. If you see certificate errors, check Caddy logs:
```bash
docker compose logs caddy
```

## ✅ Pipeline Best Practices

To leverage the DooD architecture, **always** specify a Docker agent in your pipelines. This ensures builds run in isolated containers, not on the Jenkins controller.

### Good Example (Uses Docker Agent):
```groovy
pipeline {
    agent {
        docker {
            image 'python:3.9'
        }
    }
    stages {
        stage('Test') {
            steps {
                sh 'python --version'
                sh 'pip install -r requirements.txt'
                sh 'pytest'
            }
        }
    }
}
```

### Bad Example (Runs on Controller):
```groovy
pipeline {
    agent any  // ❌ Will use the controller's executor
    stages {
        stage('Test') {
            steps {
                sh 'python --version'  // Runs on controller, may fail or cause issues
            }
        }
    }
}
```

**Recommendation:** Use `agent { docker { image '...' } }` for all production pipelines.

## 🛠 Management & Maintenance

### Changing Configuration (JCasC)
Do not change settings in the Jenkins UI. They will be lost on reboot.

1. Edit `jenkins.yaml` (e.g., to add a user or change a system message).
2. Apply changes without downtime:
   - Go to **Manage Jenkins** → **Configuration as Code**.
   - Click **Reload existing configuration**.

### Updating Plugins
1. Edit `plugins.txt`.
2. Rebuild the container:
   ```bash
   docker compose up -d --build
   ```

### Changing the Admin Password
1. Update `ADMIN_PASSWORD` in your `.env` file.
2. Restart the container to inject the new variable:
   ```bash
   docker compose up -d
   ```

## 📦 Data Persistence & Backups

* **Config:** Stored in this Git repo.
* **Data:** Stored in the `jenkins_home` Docker volume (build history, logs).
* **Certificates:** Stored in `caddy_data` volume.

**To Backup Data:**

```bash
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar czf /backup/jenkins-data-$(date +%F).tar.gz /data
```

**To Restore Data:**

```bash
docker compose down
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar xzf /backup/jenkins-data-YYYY-MM-DD.tar.gz -C /data --strip-components=1
docker compose up -d
```

## 🐛 Troubleshooting

### "Permission Denied" connecting to Docker Daemon
**Symptom:** Jenkins cannot spin up Docker agents. Pipeline fails with permission errors when trying to use Docker.

**Fix:** Double-check that the `group_add` GID in `docker-compose.yml` matches the output of `getent group docker` on your host.

```bash
# Find your Docker GID
getent group docker | cut -d: -f3

# Update docker-compose.yml to match, then restart
docker compose up -d
```

### Pipeline Stuck on "Waiting for next available executor"
**Symptom:** Build queues indefinitely without starting.

**Possible Causes:**

1. **Pipeline not using Docker agent:** If your pipeline uses `agent any` or no agent specification, it needs the controller's executor. Verify your pipeline specifies `agent { docker { ... } }`. See the "Pipeline Best Practices" section above.

2. **Disk full or Swap exhausted:** Jenkins takes the node offline when resources are critical. Check disk space (`df -h`) and swap (`free -h`).

3. **Docker socket permission issues:** See the "Permission Denied" section above.

### Browser Warnings / HTTPS Failing
**Symptom:** Certificate errors or "Your connection is not private" warnings.

**Fix:** Check Caddy logs for certificate issuance errors:

```bash
docker compose logs caddy
```

**Common causes:**
- DNS A Record not propagated or pointing to wrong IP
- Port 80 blocked (required for ACME challenge)
- Domain name mismatch in `.env` file

## 📄 License

MIT
