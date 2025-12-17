# GitHub Self-Hosted Runner Deployment Plan

## Overview

Deploy personal GitHub Actions self-hosted runners on Hetzner VM (65.108.73.119) with 1Panel integration and Docker containerization.

**Target Infrastructure:**
- Hetzner Dedicated Server: AMD Ryzen 9 3900 (12 cores, 24 threads), 128GB RAM
- 1Panel Server Management (already installed)
- Docker Container Orchestration
- Multi-runner architecture for parallelization

## Architecture

### Design Goals

✅ Cost Efficiency - No GitHub Actions minute charges  
✅ Performance - Full server resources available (vs. 2 cores on hosted runners)  
✅ Customization - Complete control over runner environment  
✅ Scalability - Multiple runners for parallel workflows  
✅ Management - 1Panel integration for easy monitoring  
✅ Reliability - Auto-restart on failure, health checks  

### Deployment Strategy

```
┌─────────────────────────────────────────────────────┐
│          Hetzner Dedicated Server (12 cores)        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │           Docker Host (native)                │  │
│  │  ────────────────────────────────────────    │  │
│  │                                              │  │
│  │  GitHub Runner 1  GitHub Runner 2  ...      │  │
│  │  (docker)         (docker)                   │  │
│  │  4 cores          4 cores                    │  │
│  │  16GB RAM         16GB RAM                   │  │
│  │                                              │  │
│  │  ┌─────────────────────────────────────┐    │  │
│  │  │ Shared Services via 1Panel:         │    │  │
│  │  │ - Docker daemon management          │    │  │
│  │  │ - Container monitoring              │    │  │
│  │  │ - Storage volumes                   │    │  │
│  │  │ - Network configuration             │    │  │
│  │  └─────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │        1Panel Server Management              │  │
│  │  - Container orchestration                   │  │
│  │  - SSH access & terminal                     │  │
│  │  - System monitoring (CPU, RAM, disk)        │  │
│  │  - Docker image management                   │  │
│  │  - Service restart policies                  │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Runner Configuration

**Primary Runner (github-runner-1)**
- 4 CPU cores, 16GB RAM
- Default workflows
- Docker support enabled
- Concurrent jobs: 1 (default)

**Secondary Runners (github-runner-2, github-runner-3)**
- 2 CPU cores each, 8GB RAM each
- Parallel job execution
- Docker support enabled
- For matrix builds and heavy workloads

## Phase 1: Preparation & Prerequisites

### 1.1 Verify Current State

```bash
# SSH to Hetzner server
ssh hetz

# Verify Docker is installed and running
sudo docker --version
sudo docker ps

# Verify 1Panel is installed
curl http://localhost:7872/ping

# Check system resources
free -h
nproc --all
df -h
```

### 1.2 GitHub Personal Access Token (PAT)

**Required for runner registration:**

1. Go to GitHub Settings → Developer Settings → Personal Access Tokens (Classic)
2. Generate new token with scopes:
   - `repo` - Full control of private repositories
   - `admin:org_hook` - Organization webhooks
   - `admin:self_hosted_runner` - Self-hosted runners
3. Save token securely (used only during registration)

**Alternative: Repository-level registration token**
- Go to Repository Settings → Actions → Runners
- Use "Add new" → Self-hosted runner
- GitHub generates short-lived registration token

### 1.3 Prepare Runner Directory Structure

```bash
ssh hetz

# Create runner directories
sudo mkdir -p /opt/github-runners/runner1
sudo mkdir -p /opt/github-runners/runner2
sudo mkdir -p /opt/github-runners/runner3

# Create shared docker-compose directory
sudo mkdir -p /opt/github-runners/docker-compose

# Set permissions
sudo chown -R $(id -u):$(id -g) /opt/github-runners
chmod 755 /opt/github-runners
```

## Phase 2: Docker Image Selection

### 2.1 Official GitHub Runner Images

**Base Options:**

1. **myoung34/github-runner** (Recommended)
   - Actively maintained
   - Pre-configured with common tools
   - Small, efficient image
   - DockerHub: `myoung34/github-runner`
   - Tags: `latest`, `ubuntu-focal`, `ubuntu-jammy`, `ubuntu-noble`

   ```bash
   docker pull myoung34/github-runner:latest
   ```

2. **Official GitHub Runner (self-hosted)**
   - GitHub's official image
   - More lightweight
   - Requires manual tool installation
   - Source: https://github.com/actions/runner

3. **ghcr.io/actions/runner**
   - GitHub Container Registry
   - Latest official builds
   - Good for enterprise use

### 2.2 Recommended Configuration: myoung34/github-runner

**Advantages:**
- Pre-installed: git, jq, curl, wget, nano, docker
- Alpine Linux base (small image)
- Well-documented
- Community tested
- Easy environment variable configuration

**Image Size:**
```
myoung34/github-runner:latest
≈ 1.5GB (with ubuntu-jammy)
≈ 800MB (with alpine)
```

## Phase 3: Docker Compose Setup

### 3.1 docker-compose.yml for Multiple Runners

**File: `/opt/github-runners/docker-compose/docker-compose.yml`**

```yaml
version: '3.8'

services:
  runner1:
    image: myoung34/github-runner:latest
    container_name: github-runner-1
    hostname: github-runner-1
    restart: unless-stopped
    environment:
      - REPO_URL=https://github.com/odenizo
      - RUNNER_TOKEN=${RUNNER_TOKEN_1}
      - RUNNER_NAME=github-runner-1
      - RUNNER_WORKDIR=/var/run/act
      - RUNNER_SCOPE=personal
      - ACCESS_TOKEN=${GITHUB_PAT}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner1-work:/var/run/act
    ports:
      - "8091:8080"
    networks:
      - runners
    cpus: '4'
    mem_limit: 16g
    healthcheck:
      test: ["CMD", "ps", "aux", "|" ,"grep", "Runner.Listener"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 10s

  runner2:
    image: myoung34/github-runner:latest
    container_name: github-runner-2
    hostname: github-runner-2
    restart: unless-stopped
    environment:
      - REPO_URL=https://github.com/odenizo
      - RUNNER_TOKEN=${RUNNER_TOKEN_2}
      - RUNNER_NAME=github-runner-2
      - RUNNER_WORKDIR=/var/run/act
      - RUNNER_SCOPE=personal
      - ACCESS_TOKEN=${GITHUB_PAT}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner2-work:/var/run/act
    ports:
      - "8092:8080"
    networks:
      - runners
    cpus: '2'
    mem_limit: 8g
    healthcheck:
      test: ["CMD", "ps", "aux", "|" ,"grep", "Runner.Listener"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 10s
    depends_on:
      - runner1

volumes:
  runner1-work:
    driver: local
  runner2-work:
    driver: local

networks:
  runners:
    driver: bridge
```

### 3.2 Environment File (.env)

**File: `/opt/github-runners/docker-compose/.env`**

```bash
# GitHub Access Token (Personal Access Token)
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Runner registration tokens (temporary, generated per runner)
RUNNER_TOKEN_1=xxxxx
RUNNER_TOKEN_2=xxxxx

# Runner configuration
RUNNER_WORKDIR=/var/run/act
```

**⚠️ SECURITY:** Never commit `.env` to version control

## Phase 4: Installation & Registration

### 4.1 Manual Runner Token Generation

**For Repository-level runners:**

1. Go to `https://github.com/odenizo/<repo-name>/settings/actions/runners/new`
2. Select "Linux" and "X64"
3. GitHub generates a short-lived token
4. Copy the token and save to `.env` file

**Or use GitHub CLI:**

```bash
gh auth login
gh runner create --owner odenizo --name github-runner-1
```

### 4.2 Deploy Runners with Docker Compose

```bash
cd /opt/github-runners/docker-compose

# Create .env with tokens
cat > .env << 'EOF'
GITHUB_PAT=ghp_xxxxxxxxxxxx
RUNNER_TOKEN_1=xxxxx
RUNNER_TOKEN_2=xxxxx
EOF

# Change permissions
chmod 600 .env

# Start runners
sudo docker-compose up -d

# Verify runners are running
sudo docker-compose ps

# Check logs
sudo docker-compose logs -f runner1
```

### 4.3 Verify Registration in GitHub

```bash
# Check runner status in GitHub UI
# Go to: Settings → Actions → Runners → Personal runners
# Should see:
# - github-runner-1: Online (Idle)
# - github-runner-2: Online (Idle)

# Or via GitHub CLI
gh runner list --owner odenizo
```

## Phase 5: 1Panel Integration

### 5.1 Check 1Panel App Store for GitHub Runner

**Access 1Panel:**
1. Open browser: `https://<hetzner-ip>:7872`
2. Login with 1Panel credentials
3. Go to "App Store" section
4. Search: "github", "runner", "actions"

**Expected Apps:**
- GitHub Runner (if available)
- Docker (already installed)
- Portainer (optional, for Docker UI)

### 5.2 If No GitHub Runner App Exists

**Option A: Add Custom Docker Compose Application**

1. In 1Panel: "Applications" → "Add Application" → "Docker Compose"
2. Upload `docker-compose.yml`
3. Provide `.env` file
4. Deploy
5. Monitor in 1Panel dashboard

**Option B: Manual Docker Compose (Recommended)**

Use SSH and docker-compose directly (see Phase 4)

### 5.3 Monitor Runners in 1Panel

```bash
# View in 1Panel:
# - Containers → github-runner-1, github-runner-2
# - CPU/Memory usage
# - Logs
# - Port mappings (8091, 8092)

# Via Docker directly:
sudo docker ps | grep github-runner
sudo docker stats github-runner-1
sudo docker logs -f github-runner-1
```

## Phase 6: Testing & Validation

### 6.1 Create Test Workflow

**File: `.github/workflows/test-runner.yml`**

```yaml
name: Test Self-Hosted Runner

on:
  push:
    branches: [ main, dev ]
  workflow_dispatch:

jobs:
  test:
    runs-on: self-hosted
    steps:
      - name: Check runner
        run: |
          echo "Runner: $(hostname)"
          echo "CPU: $(nproc --all)"
          echo "RAM: $(free -h | grep Mem)"
          echo "Docker: $(docker --version)"
          echo "GitHub Actions: ${{ runner.os }}"
      
      - name: Test Docker in runner
        run: docker run --rm hello-world
      
      - name: Test artifact upload
        run: echo "Test artifact" > artifact.txt
      
      - uses: actions/upload-artifact@v3
        with:
          name: test-artifact
          path: artifact.txt
```

### 6.2 Test Multiple Runners (Parallel)

**File: `.github/workflows/matrix-test.yml`**

```yaml
name: Matrix Test

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: self-hosted
    strategy:
      matrix:
        job: [1, 2, 3]
    steps:
      - run: echo "Job ${{ matrix.job }} on runner $(hostname)"
      - run: sleep 30
```

### 6.3 Monitor Test Execution

```bash
# Watch runner activity
ssh hetz
sudo docker logs -f github-runner-1 | grep "Running job"

# Check GitHub UI
# Repository → Actions → Workflows
# Should see test jobs running on self-hosted runner
```

## Phase 7: Scale-Out Configuration

### 7.1 Add More Runners

To add runner-3, runner-4, etc:

```bash
# Add to docker-compose.yml
cat >> docker-compose.yml << 'EOF'

  runner3:
    image: myoung34/github-runner:latest
    container_name: github-runner-3
    hostname: github-runner-3
    restart: unless-stopped
    environment:
      - REPO_URL=https://github.com/odenizo
      - RUNNER_TOKEN=${RUNNER_TOKEN_3}
      - RUNNER_NAME=github-runner-3
      - RUNNER_WORKDIR=/var/run/act
      - RUNNER_SCOPE=personal
      - ACCESS_TOKEN=${GITHUB_PAT}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner3-work:/var/run/act
    networks:
      - runners
    cpus: '2'
    mem_limit: 8g
    depends_on:
      - runner1

volumes:
  runner3-work:
    driver: local
EOF

# Restart compose
sudo docker-compose down
sudo docker-compose up -d
```

### 7.2 Labels and Targeting

Run workflows on specific runners:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64]
    steps:
      - run: echo "On default runner"

  test:
    runs-on: self-hosted  # Uses first available
    steps:
      - run: echo "On any runner"
```

## Phase 8: Monitoring & Maintenance

### 8.1 Health Checks

```bash
# Check runner process
ssh hetz
sudo docker exec github-runner-1 ps aux | grep Runner.Listener

# Check runner connectivity
sudo docker logs github-runner-1 | grep -i "connected\|registered\|error"

# View system stats
sudo docker stats github-runner-1

# Check disk usage
du -sh /var/run/act/*/
```

### 8.2 Auto-Restart Policy

Docker Compose is configured with `restart: unless-stopped`

```bash
# This means runners restart automatically if:
# - Container crashes
# - Docker daemon restarts
# - Server reboots

# Manual restart if needed
sudo docker-compose restart runner1
```

### 8.3 Cleanup Old Workflow Files

```bash
# Runners accumulate workflow artifacts
# Clean monthly

cat > /opt/github-runners/cleanup.sh << 'EOF'
#!/bin/bash
find /opt/github-runners/runner*/act/*/s -type f -mtime +30 -delete
echo "Cleaned old workflow files"
EOF

chmod +x /opt/github-runners/cleanup.sh

# Add to crontab
sudo crontab -e
# Add: 0 2 1 * * /opt/github-runners/cleanup.sh
EOF
```

## Phase 9: Security Hardening

### 9.1 Network Isolation

```yaml
# Restrict runner network access
networks:
  runners:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_ip_masquerade: "false"
```

### 9.2 Runner User Permissions

```bash
# Don't run runners as root
# Add to docker-compose:
user: "1000:1000"  # Non-root user
```

### 9.3 Secure Token Management

```bash
# Store tokens in 1Panel secrets or encrypted .env
# Use GitHub Secrets for sensitive data in workflows
# Rotate PAT tokens regularly (GitHub → Settings → Developer Settings)
```

## Phase 10: Troubleshooting Guide

### Runner Not Connecting

```bash
# Check runner logs
sudo docker logs github-runner-1 | tail -50

# Verify token is valid
# Regenerate registration token if expired

# Check network connectivity
sudo docker exec github-runner-1 curl -I https://github.com
```

### High Memory Usage

```bash
# Check which workflow is consuming memory
sudo docker stats github-runner-1

# Limit concurrent jobs
# Edit runner config or use runner groups
```

### Docker-in-Docker Issues

```bash
# Verify Docker socket is mounted
sudo docker exec github-runner-1 docker ps

# If fails, check:
# - /var/run/docker.sock is readable
# - Docker daemon is running
sudo dockerd status
```

## Performance Expectations

### Comparison: GitHub Hosted vs Self-Hosted

| Metric | GitHub Hosted | Self-Hosted (Hetzner) |
|--------|---------------|-----------------------|
| CPUs | 2 cores | 12 cores available |
| RAM | 7GB | 128GB available |
| Startup | ~2 min | ~10 sec |
| Cost | $0.008/min | Fixed monthly |
| Build time (example) | 5 minutes | 1-2 minutes |
| Storage | 14GB | 3.84TB NVMe |

### Estimated ROI

**Monthly GitHub Actions cost (if hosted):**
- 100 workflows/month × 5 min average = 500 min
- 500 min × $0.008/min = **$4**

**Hetzner server cost:** ~$50/month (using existing server)

**Break-even:** ~2000+ workflow minutes/month or complex workflows

## Files to Create

```
/opt/github-runners/
├── docker-compose/
│   ├── docker-compose.yml       # Main compose file
│   ├── .env                      # Environment variables (encrypted)
│   └── .env.example              # Template (no secrets)
├── cleanup.sh                    # Monthly cleanup script
├── monitoring.sh                 # Health check script
├── SETUP_CHECKLIST.md            # Setup steps
└── TROUBLESHOOTING.md            # Common issues
```

## Next Steps

1. ✅ Get GitHub PAT token
2. ✅ Generate runner registration tokens
3. ✅ Create docker-compose.yml
4. ✅ Deploy runners on Hetzner
5. ✅ Verify in GitHub UI
6. ✅ Test with sample workflow
7. ✅ Integrate with 1Panel monitoring
8. ✅ Scale to additional runners as needed

## References

- [GitHub Actions Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [Official GitHub Runner GitHub](https://github.com/actions/runner)
- [myoung34/github-runner Docker Image](https://hub.docker.com/r/myoung34/github-runner)
- [1Panel Documentation](https://1panel.io/docs/)
- [Hetzner CI Setup Reference](https://github.com/decentriq/hetzner-ci-setup)

---

**Last Updated:** 2024-12-17  
**Status:** Planning Phase  
**Owner:** Personal Infrastructure  
