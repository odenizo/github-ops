# GitHub Runner Setup Checklist

## Pre-Deployment Verification

### Prerequisites
- [ ] Hetzner SSH access configured (`ssh hetz` works)
- [ ] 1Panel installed and accessible (https://<ip>:7872)
- [ ] Docker installed on Hetzner server
- [ ] GitHub account access with ability to manage runners
- [ ] GitHub Personal Access Token with scope permissions

## Phase 1: Gather Information

### 1.1 GitHub Setup
- [ ] Create GitHub Personal Access Token (PAT)
  ```bash
  # At: https://github.com/settings/tokens
  # Scopes: repo, admin:org_hook, admin:self_hosted_runner
  # Save token: ghp_xxxxxxxxxxxxxxxx
  ```
- [ ] Note repository to register runners for: `___________`
- [ ] Generate first runner registration token
  ```bash
  # At: https://github.com/odenizo/[REPO]/settings/actions/runners/new
  # Token: ___________
  ```

### 1.2 Server Information
- [ ] Verify SSH access:
  ```bash
  ssh hetz
  ```
  - [ ] Command successful
  - [ ] Server responds: `_______@_______`

- [ ] Verify Docker:
  ```bash
  ssh hetz
  sudo docker --version
  ```
  - [ ] Docker version: `_______`
  - [ ] Docker daemon running: `sudo docker ps` works

- [ ] Check system resources:
  ```bash
  ssh hetz
  free -h
  nproc --all
  df -h /
  ```
  - [ ] Available RAM: `_______` GB
  - [ ] Available CPUs: `_______` cores
  - [ ] Available disk: `_______` GB

### 1.3 1Panel Status
- [ ] Access 1Panel: https://<hetzner-ip>:7872
  - [ ] Login successful
  - [ ] Can see "App Store" section
- [ ] Search in 1Panel App Store:
  - [ ] Search "github" - apps found: `_______`
  - [ ] Search "runner" - apps found: `_______`
  - [ ] Search "docker compose" - apps found: `_______`

## Phase 2: Directory Setup

- [ ] Create runner directories:
  ```bash
  ssh hetz
  sudo mkdir -p /opt/github-runners/docker-compose
  sudo chown -R $(id -u):$(id -g) /opt/github-runners
  chmod 755 /opt/github-runners
  
  # Verify:
  ls -la /opt/github-runners
  ```
  - [ ] Directories created
  - [ ] Permissions set correctly

## Phase 3: Configuration Files

### 3.1 Create docker-compose.yml

- [ ] Copy template from deployment plan
- [ ] Save to: `/opt/github-runners/docker-compose/docker-compose.yml`
- [ ] Verify:
  ```bash
  ssh hetz
  cat /opt/github-runners/docker-compose/docker-compose.yml | head -20
  ```
  - [ ] File exists and readable

### 3.2 Create .env file

- [ ] Create `/opt/github-runners/docker-compose/.env`
  ```bash
  ssh hetz
  cd /opt/github-runners/docker-compose
  cat > .env << 'EOF'
  GITHUB_PAT=ghp_xxxxxxxxxxxx
  RUNNER_TOKEN_1=xxxxx
  RUNNER_TOKEN_2=xxxxx
  EOF
  
  chmod 600 .env
  ```
  - [ ] File created
  - [ ] Permissions: 600 (only owner can read)
  - [ ] GitHub PAT entered: `ghp_______`
  - [ ] Runner Token 1 entered: `_______`
  - [ ] Runner Token 2 entered: `_______`

### 3.3 Verify Configuration

- [ ] Check docker-compose syntax:
  ```bash
  ssh hetz
  cd /opt/github-runners/docker-compose
  sudo docker-compose config > /dev/null && echo "Config valid" || echo "Config invalid"
  ```
  - [ ] Output: "Config valid"

- [ ] Verify .env is loaded:
  ```bash
  sudo docker-compose config | grep GITHUB_PAT
  ```
  - [ ] Shows environment variables

## Phase 4: Docker Image Verification

- [ ] Check if image already downloaded:
  ```bash
  ssh hetz
  sudo docker images | grep myoung34
  ```
  - [ ] Image found: `_______`
  - [ ] Image not found (will be pulled during first run)

## Phase 5: Deploy Runners

### 5.1 Start Containers

- [ ] Start runner services:
  ```bash
  ssh hetz
  cd /opt/github-runners/docker-compose
  sudo docker-compose up -d
  ```
  - [ ] Command successful
  - [ ] No errors in output

### 5.2 Verify Running

- [ ] Check container status:
  ```bash
  sudo docker-compose ps
  ```
  - [ ] github-runner-1: STATE = `Up`
  - [ ] github-runner-2: STATE = `Up` (if configured)
  - [ ] All containers healthy

- [ ] Check container logs:
  ```bash
  sudo docker-compose logs runner1 | tail -20
  ```
  - [ ] Look for: "Connected to" or "Runner ready"
  - [ ] No error messages
  - [ ] Log output: `_______________________`

### 5.3 Verify Docker Stats

- [ ] Check CPU/Memory usage:
  ```bash
  sudo docker stats --no-stream github-runner-1
  ```
  - [ ] CPU: `_______` %
  - [ ] Memory: `_______` MB / `_______` MB
  - [ ] Both runners running and consuming resources

## Phase 6: GitHub UI Verification

- [ ] Check runner registration:
  - [ ] Go to: https://github.com/odenizo/<repo>/settings/actions/runners
  - [ ] Runners visible:
    - [ ] `github-runner-1`: Status = **Online** (Idle)
    - [ ] `github-runner-2`: Status = **Online** (Idle)
  - [ ] Last activity: Current (within last 1 minute)

- [ ] Verify runner details:
  ```bash
  gh runner list --owner odenizo
  ```
  - [ ] Runner 1 listed: `_______`
  - [ ] Runner 2 listed: `_______`
  - [ ] Both showing as "online"

## Phase 7: 1Panel Integration

### 7.1 Access 1Panel

- [ ] Open 1Panel: https://<hetzner-ip>:7872
- [ ] Navigate to: Containers or Applications
- [ ] Look for runners:
  - [ ] Container: `github-runner-1` - Status: **Running**
  - [ ] Container: `github-runner-2` - Status: **Running**
  - [ ] CPU usage visible
  - [ ] Memory usage visible

### 7.2 Verify Port Mappings

- [ ] Check 1Panel container details:
  - [ ] runner1 ports: `8091 -> 8080`
  - [ ] runner2 ports: `8092 -> 8080` (if configured)
  - [ ] Ports are accessible

### 7.3 Check 1Panel App Store

- [ ] Search for "github runner" app:
  - [ ] GitHub Runner app found: [ ] Yes [ ] No
  - [ ] If found, version: `_______`
  - [ ] Rating/reviews: `_______`
- [ ] If app available, note for future automated deployment

## Phase 8: Test Workflow Execution

### 8.1 Create Test Workflow

- [ ] Create file: `.github/workflows/test-runner.yml`
  ```bash
  mkdir -p .github/workflows
  cat > .github/workflows/test-runner.yml << 'EOF'
  name: Test Self-Hosted Runner
  on: [push, workflow_dispatch]
  jobs:
    test:
      runs-on: self-hosted
      steps:
        - run: echo "Runner: $(hostname)"
        - run: echo "CPUs: $(nproc --all)"
        - run: docker run --rm hello-world
  EOF
  ```
  - [ ] File created
  - [ ] Committed to repository

### 8.2 Trigger Test Workflow

- [ ] Go to: Repository → Actions → Test Self-Hosted Runner
  - [ ] Click "Run workflow" → "Run workflow"
  - [ ] Workflow queued

- [ ] Monitor execution:
  ```bash
  ssh hetz
  sudo docker-compose logs -f runner1 | grep -i "job\|running"
  ```
  - [ ] Job starts running
  - [ ] Output shows: `Running job...`
  - [ ] Job completes successfully

- [ ] Verify in GitHub UI:
  - [ ] Workflow shows as completed
  - [ ] Status: ✅ Success
  - [ ] Duration: `_______` seconds
  - [ ] Output shows runner name and CPU count

### 8.3 Check GitHub UI Status

- [ ] Go to: Settings → Actions → Runners
  - [ ] Runner status updated
  - [ ] Last activity timestamp: Recent
  - [ ] Status: **Online** (was running job, now Idle)

## Phase 9: Performance Testing

- [ ] Run matrix workflow:
  ```bash
  # Trigger workflow with matrix
  ```
  - [ ] Multiple jobs execute in parallel
  - [ ] Each job on different runner
  - [ ] No resource conflicts
  - [ ] All jobs complete successfully

- [ ] Monitor resource usage:
  ```bash
  ssh hetz
  watch -n 1 'sudo docker stats --no-stream'
  ```
  - [ ] CPU usage: `_______` %
  - [ ] Memory usage: `_______` MB
  - [ ] No OOM (out of memory) errors
  - [ ] Disk not filling up

## Phase 10: Security Verification

- [ ] Verify token security:
  - [ ] PAT not in any logs: `grep -r 'ghp_' /opt/github-runners`
    - [ ] Result: No matches
  - [ ] `.env` file permissions: 600
    - [ ] Only owner can read
  - [ ] `.env` not committed to repo:
    - [ ] Check: `git log --all --full-history -- .env | wc -l`
    - [ ] Result: 0 (not in history)

- [ ] Verify Docker socket permissions:
  ```bash
  ls -la /var/run/docker.sock
  ```
  - [ ] Readable by runner user
  - [ ] Permissions: `srw-rw----` or similar

## Phase 11: Monitoring Setup

- [ ] Create health check script:
  ```bash
  cat > /opt/github-runners/check-runners.sh << 'EOF'
  #!/bin/bash
  echo "=== Runner Status ==="
  docker-compose -f /opt/github-runners/docker-compose/docker-compose.yml ps
  echo ""
  echo "=== Resource Usage ==="
  docker stats --no-stream github-runner-1 github-runner-2
  EOF
  chmod +x /opt/github-runners/check-runners.sh
  ```
  - [ ] Script created
  - [ ] Executable: `chmod +x`
  - [ ] Test: `bash /opt/github-runners/check-runners.sh`

- [ ] Optional: Add to crontab for alerts
  ```bash
  sudo crontab -e
  # Add: 0 * * * * /opt/github-runners/check-runners.sh >> /var/log/runners.log
  ```
  - [ ] Hourly monitoring configured

## Phase 12: Documentation

- [ ] Update infrastructure docs:
  - [ ] Add runner deployment to personal-hq README
  - [ ] Document runner token rotation schedule
  - [ ] Document backup/restore procedures

- [ ] Create operational guide:
  - [ ] How to add new runners
  - [ ] How to remove runners
  - [ ] How to restart runners
  - [ ] How to upgrade runner version

## Phase 13: Troubleshooting

If runners not showing as Online:
- [ ] Check logs: `sudo docker-compose logs runner1 | tail -50`
- [ ] Verify token not expired
- [ ] Verify network connectivity: `docker exec github-runner-1 curl -I https://github.com`
- [ ] Check firewall: `sudo iptables -L | grep 443`
- [ ] Restart runner: `sudo docker-compose restart runner1`

If runners disconnected:
- [ ] Check if Docker daemon crashed: `sudo systemctl status docker`
- [ ] Check disk space: `df -h /var/run/act`
- [ ] Check memory: `free -h`
- [ ] Check logs: `sudo docker logs github-runner-1`

If workflow hangs:
- [ ] Check runner process: `docker exec github-runner-1 ps aux | grep runner`
- [ ] Check disk space: `docker exec github-runner-1 df -h`
- [ ] Manually restart: `sudo docker-compose restart runner1`

## Final Sign-Off

- [ ] All tests passing
- [ ] Runners stable and healthy
- [ ] 1Panel monitoring configured
- [ ] Documentation updated
- [ ] Team notified of new runners
- [ ] Performance baseline recorded

**Date Completed:** `_______`  
**Completed By:** `_______`  
**Notes:** `_______________________________`

---

**Estimated Time:** 1-2 hours  
**Complexity:** Medium  
**Risk Level:** Low (non-production testing first)  
