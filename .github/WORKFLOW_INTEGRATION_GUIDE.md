# GitHub Actions Workflow Integration Guide

**Document Version:** 1.0  
**Last Updated:** December 17, 2025  
**Scope:** Hetzner VM + MacBook multi-environment execution

---

## Overview

This guide explains how to use two custom GitHub Actions workflows to execute terminal commands on different environments:

1. **Hetzner VM Workflow** (`run-terminal-command-hetzner.yml`)
   - Targets self-hosted runners deployed via Docker Compose on Hetzner
   - Supports parallel execution (runner-1: 4 cores/16GB, runner-2: 2 cores/8GB)
   - Ideal for server-side operations, deployments, batch processing

2. **MacBook Workflow** (`run-terminal-command-macbook.yml`)
   - Targets self-hosted runner on personal MacBook (macOS)
   - Includes SSH integration to Hetzner VM for result synchronization
   - Ideal for macOS-specific operations, local development, testing

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│         GitHub Actions (github-ops)                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────┐       ┌──────────────────────┐ │
│  │ Hetzner VM Workflow  │       │ MacBook Workflow     │ │
│  ├──────────────────────┤       ├──────────────────────┤ │
│  │ - runner-1 (4c/16GB) │       │ - SSH Integration    │ │
│  │ - runner-2 (2c/8GB)  │       │ - Local Environment  │ │
│  │ - Docker Compose     │       │ - Xcode Tools        │ │
│  │ - Parallel exec      │       │ - Package Managers   │ │
│  │ - Health checks      │       │ - SSH Sync to HZ     │ │
│  └──────────────────────┘       └──────────────────────┘ │
│           │                             │                 │
│           └─────────────────┬───────────┘                 │
│                             │                             │
│                    Coordination via:                       │
│                  - GitHub Secrets                         │
│                  - Artifacts storage                      │
│                  - Neo4j (planned)                        │
│                                                           │
└─────────────────────────────────────────────────────────┘
         │                                  │
         ▼                                  ▼
    ┌─────────────┐                  ┌──────────────┐
    │ Hetzner VM  │                  │   MacBook    │
    │ (Linux)     │───SSH tunnel───▶ (macOS)       │
    │ 12c/128GB   │                  │              │
    └─────────────┘                  └──────────────┘
```

---

## Part 1: Hetzner VM Workflow Setup

### Prerequisites

1. ✅ Docker Compose runners deployed (via `GITHUB_RUNNER_DOCKER_COMPOSE.yml`)
   - `github-runner-1`: 4 cores, 16GB RAM
   - `github-runner-2`: 2 cores, 8GB RAM
   - Network: `runners` bridge (172.25.0.0/16)

2. ✅ GitHub Actions registered on Hetzner runners
   - Check status: `docker ps | grep github-runner`
   - Verify registration: GitHub UI → Settings → Runners

### Configuration

**File:** `.github/workflows/run-terminal-command-hetzner.yml`

**Runner Labels:**
```yaml
# Single runner (primary, 4 cores/16GB)
runs-on: [self-hosted, linux, x64, hetzner]

# With secondary label (2 cores/8GB)
runs-on: [self-hosted, linux, x64, hetzner, secondary]

# Generic self-hosted
runs-on: [self-hosted]
```

**Resource Allocation:**
- Runner-1 (Primary): 4 CPU cores, 16GB RAM, 2GB swap
- Runner-2 (Secondary): 2 CPU cores, 8GB RAM, 1GB swap
- Total available: 6 cores, 24GB (on 12-core, 128GB server)

### Features

✅ **Health Checks**
- Docker daemon verification
- Runner status check
- System resource monitoring

✅ **Execution Modes**
- Serial: Single runner execution (default)
- Parallel: Both runners execute simultaneously (optional)

✅ **Output Logging**
- Real-time command output
- Structured metrics capture
- GitHub Actions artifacts upload
- 7-day retention policy

✅ **Error Handling**
- Exit code capture
- Execution timeout (3600s default)
- Non-blocking failure modes

### Usage Examples

**Via GitHub CLI:**
```bash
# Simple command execution
gh workflow run run-terminal-command-hetzner.yml \
  -f command="echo 'Hello from Hetzner'" \
  -f runner_label="self-hosted,linux,x64,hetzner"

# Complex deployment
gh workflow run run-terminal-command-hetzner.yml \
  -f command="docker-compose -f /opt/github-runners/docker-compose.yml ps" \
  -f log_level="debug"

# Parallel execution
gh workflow run run-terminal-command-hetzner.yml \
  -f command="uname -a" \
  -f use_parallel="true"
```

**Via GitHub UI:**
1. Go to: Actions → "Run Terminal Command - Hetzner VM"
2. Click: "Run workflow"
3. Fill in:
   - Command: Your terminal command
   - Runner label: Select from dropdown
   - Use parallel: Check if needed
   - Log level: Choose verbosity
4. Click: "Run workflow"

---

## Part 2: MacBook Workflow Setup

### Prerequisites

1. ✅ GitHub Actions runner installed on MacBook
   - Installation: `https://github.com/your-org/settings/actions/runners/new`
   - Run: `/Users/username/actions-runner/run.sh`

2. ✅ SSH key configured (for Hetzner sync)
   ```bash
   # Generate SSH key
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   
   # Add to ssh-agent
   ssh-add ~/.ssh/id_ed25519
   
   # Configure ~/.ssh/config
   Host hetzner-vm
     HostName <hetzner-ip>
     User runner
     IdentityFile ~/.ssh/id_ed25519
     StrictHostKeyChecking=no
     UserKnownHostsFile=/dev/null
   ```

3. ✅ Public key added to Hetzner VM
   ```bash
   # On Hetzner:
   mkdir -p ~/.ssh
   cat >> ~/.ssh/authorized_keys << 'EOF'
   <content of ~/.ssh/id_ed25519.pub from MacBook>
   EOF
   chmod 600 ~/.ssh/authorized_keys
   ```

### Configuration

**File:** `.github/workflows/run-terminal-command-macbook.yml`

**Runner Labels:**
```yaml
# MacBook self-hosted runner
runs-on: [self-hosted, macos, macbook]

# Generic macOS
runs-on: [self-hosted, macos]

# With personal designation
runs-on: [self-hosted, macos, macbook, personal]
```

**GitHub Secrets (Set in Settings → Secrets):**
```bash
HETZNER_HOST=<ip-or-hostname>
HETZNER_USER=runner
```

### Features

✅ **System Information**
- macOS version and build
- CPU/Memory/Disk specs
- Xcode and development tools status

✅ **Shell Support**
- Bash (default)
- Zsh
- Fish

✅ **Environment Integration**
- Load ~/.bashrc and ~/.zshrc
- Preserve local PATH
- Access to Xcode Command Line Tools

✅ **SSH Integration**
- SSH connection verification
- Automatic result sync to Hetzner
- Non-blocking SSH failures

✅ **Output Management**
- Local GitHub Actions artifacts
- Optional Hetzner VM sync
- Timestamped result directories

### Usage Examples

**Via GitHub CLI:**
```bash
# Check Swift version
gh workflow run run-terminal-command-macbook.yml \
  -f command="swift --version" \
  -f shell_type="bash"

# Run Python script
gh workflow run run-terminal-command-macbook.yml \
  -f command="python3 -c 'print(\"Hello from MacBook\")'"

# Build Xcode project
gh workflow run run-terminal-command-macbook.yml \
  -f command="xcodebuild -scheme MyApp -configuration Release" \
  -f upload_to_hetzner="true"

# Execute with Zsh
gh workflow run run-terminal-command-macbook.yml \
  -f command="source ~/.zshrc && my-custom-command" \
  -f shell_type="zsh"
```

**Via GitHub UI:**
1. Go to: Actions → "Run Terminal Command - MacBook"
2. Click: "Run workflow"
3. Fill in:
   - Command: Your macOS terminal command
   - Shell type: bash/zsh/fish
   - Upload to Hetzner: Check if syncing needed
   - Log level: Choose verbosity
4. Click: "Run workflow"

---

## Part 3: Multi-Agent Coordination

Based on `personal-hq/AGENTS.md`, here's how to use the workflows with multi-agent orchestration:

### Agent Selection Matrix

| Workflow | Agent | Rationale |
|----------|-------|----------|
| **Hetzner** | Claude Code (Orchestrator) | Complex infrastructure decisions |
| **Hetzner** | Gemini CLI | Fast execution and transformations |
| **MacBook** | GitHub Copilot | Quick suggestions and IDE integration |
| **MacBook** | Claude Code | Complex local operations |
| **Async Sync** | Perplexity | Research and external data |

### Example: Infrastructure Deployment Workflow

```
Trigger: User requests "Deploy Neo4j to Hetzner"

1. Claude Code (Orchestrator)
   └─ Reads: admin/context.json, deployment scripts
   └─ Plans: Phased approach
   └─ Delegates: "Trigger Hetzner workflow"

2. GitHub Actions - Hetzner Workflow
   └─ Command: docker-compose up -d neo4j
   └─ Runs on: github-runner-1 (primary, 4 cores/16GB)
   └─ Captures: Deployment logs, metrics
   └─ Output: Artifacts → GitHub Actions

3. Claude Code (Reviewer)
   └─ Receives: Deployment results
   └─ Validates: Against checklist
   └─ Updates: Neo4j graph, context.json
   └─ Reports: Success/failure
```

### Example: Cross-Environment Build

```
Trigger: User requests "Build and test on MacBook, deploy from Hetzner"

1. GitHub Copilot (Quick Suggester)
   └─ Suggests: Build commands for macOS
   └─ Offers: Testing framework options

2. GitHub Actions - MacBook Workflow
   └─ Command: xcodebuild -scheme App -test
   └─ Local environment: Full Xcode setup
   └─ Output: Build artifacts + test results
   └─ Sync: Results to Hetzner via SSH

3. Claude Code (Processor)
   └─ Receives: MacBook build results
   └─ Analyzes: Test coverage, build time
   └─ Delegates: "Trigger Hetzner deployment"

4. GitHub Actions - Hetzner Workflow
   └─ Command: Deploy artifacts from /opt/github-runners/macbook-results/
   └─ Updates: Production environment
   └─ Reports: Deployment status
```

---

## Part 4: Triggering Workflows

### Via GitHub CLI

**Installation:**
```bash
# macOS
brew install gh

# Or download from https://github.com/cli/cli
gh --version
```

**Authentication:**
```bash
gh auth login
# Select: GitHub.com
# Select: SSH
# Authenticate in browser
```

**Trigger Workflow:**
```bash
# List available workflows
gh workflow list --repo odenizo/github-ops

# Trigger Hetzner workflow
gh workflow run run-terminal-command-hetzner.yml \
  --repo odenizo/github-ops \
  -f command="your command here"

# Trigger MacBook workflow
gh workflow run run-terminal-command-macbook.yml \
  --repo odenizo/github-ops \
  -f command="your command here"

# Watch workflow execution
gh run list --workflow run-terminal-command-hetzner.yml
gh run view <run-id> --log  # View logs
```

### Via GitHub API

```bash
# Get workflow ID
WORKFLOW_ID=$(gh api repos/odenizo/github-ops/actions/workflows | jq '.workflows[] | select(.name | contains("Hetzner")) | .id')

# Trigger with inputs
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/odenizo/github-ops/actions/workflows/$WORKFLOW_ID/dispatches \
  -d '{"ref":"main","inputs":{"command":"echo test","runner_label":"self-hosted"}}'
```

### Via GitHub UI

1. Navigate to: https://github.com/odenizo/github-ops/actions
2. Select workflow: "Run Terminal Command - Hetzner VM" or "Run Terminal Command - MacBook"
3. Click: "Run workflow"
4. Fill in parameters
5. Click: "Run workflow"
6. View progress in real-time

---

## Part 5: Output & Results

### Hetzner VM Outputs

**Location:** GitHub Actions Artifacts
- **File:** `hetzner-execution-logs.zip`
- **Contents:**
  ```
  outputs/hetzner/
  ├── logs/
  │   └── command_output.log          # Full command output
  ├── artifacts/                       # Any generated files
  └── metrics/
      └── stats.md                     # Execution metrics
  ```

**Metrics Captured:**
- Exit code
- Execution duration
- CPU/Memory usage
- Disk I/O
- Runner hostname
- Timestamp (UTC)

### MacBook Outputs

**Location:** GitHub Actions Artifacts + Hetzner VM
- **GitHub:** `macbook-execution-logs.zip`
- **Hetzner:** `/opt/github-runners/macbook-results/<date>/`

**Contents:**
```
outputs/macbook/
├── logs/
│   └── command_output.log           # Full command output
├── artifacts/                        # Generated files
└── metrics/
    └── stats.md                      # System metrics
```

**Metrics Captured:**
- Exit code
- Execution duration
- CPU/Memory (macOS specific)
- Disk usage
- Runner hostname
- Timestamp (UTC)

---

## Part 6: Troubleshooting

### Hetzner Runner Issues

**Problem: Runner not appearing in GitHub Actions**
```bash
# Check if runner container is running
docker ps | grep github-runner

# View runner logs
docker logs github-runner-1

# Restart runner
docker restart github-runner-1

# Check registration token (expires after 1 hour)
# Re-register: https://github.com/odenizo/github-ops/settings/actions/runners
```

**Problem: Insufficient resources**
```bash
# Check Docker resource limits
docker inspect github-runner-1 | grep -A 10 '"CpuQuota"'

# Verify available system resources
free -h           # Memory
df -h /           # Disk
nproc             # CPU cores

# Reduce parallel jobs or increase runner resources
# Edit: deployments/GITHUB_RUNNER_DOCKER_COMPOSE.yml
```

**Problem: Commands timeout**
```bash
# Increase timeout (default 3600s)
# Edit workflow: run-terminal-command-hetzner.yml
# Set: COMMAND_TIMEOUT=7200

# Or optimize command execution
# Profile slow operations
time <your-command>
```

### MacBook Runner Issues

**Problem: Runner not registered**
```bash
# Check runner process
ps aux | grep actions-runner

# Verify runner directory
ls -la ~/actions-runner/

# Reinstall runner
cd ~/actions-runner
./config.sh remove
./config.sh --url https://github.com/odenizo/github-ops --token <token>
./run.sh
```

**Problem: SSH sync failing**
```bash
# Test SSH connection
ssh -v hetzner-vm echo OK

# Check SSH key
ls -la ~/.ssh/id_ed25519*

# Verify known hosts
ssh-keyscan hetzner-vm >> ~/.ssh/known_hosts

# Add to GitHub Secrets:
# Settings → Secrets → New repository secret
# Name: HETZNER_HOST
# Value: <ip-or-hostname>
```

**Problem: Environment not loading**
```bash
# Verify bashrc/zshrc
cat ~/.bashrc
cat ~/.zshrc

# Test shell directly
/bin/bash -c 'source ~/.bashrc; echo $PATH'

# Check runner shell config
# Edit: ~/.actions-runner/.env (if exists)
```

### Common GitHub Actions Issues

**Problem: Workflow not appearing**
```bash
# Verify file location
ls -la .github/workflows/*.yml

# Check YAML syntax
yaml-lint .github/workflows/run-terminal-command-*.yml

# Or use GitHub UI: Settings → Actions → General
```

**Problem: Secrets not accessible**
```bash
# Verify secrets exist
gh secret list --repo odenizo/github-ops

# Set missing secrets
gh secret set HETZNER_HOST --body "<value>" --repo odenizo/github-ops

# Note: Secrets are masked in logs
```

---

## Part 7: Security Considerations

### SSH Key Management

**Generate secure key:**
```bash
# Ed25519 (recommended)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "macbook-github-runner"

# Add passphrase
ssh-keygen -p -f ~/.ssh/id_ed25519
```

**Store in GitHub Secrets:**
```bash
# NOT recommended - SSH key in secrets
# Instead, use SSH config + authorized_keys
```

**Permissions:**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/config
```

### Runner Health Monitoring

**Hetzner VM:**
```bash
# Monitor runner health
watch -n 5 'docker ps --filter label=service=github-runner-1'

# Check resource usage
docker stats github-runner-1

# Review runner logs
docker logs -f github-runner-1
```

**MacBook:**
```bash
# Monitor runner process
ps aux | grep actions-runner

# Check disk space
df -h ~

# Monitor resource usage
top -o %CPU -o %MEM
```

### Audit & Logging

**GitHub Actions logs:**
- Stored for 90 days (default)
- Searchable by workflow, runner, status
- Downloadable as artifacts

**Neo4j Integration (future):**
- All executions logged to graph database
- Queryable by date, command, result
- Temporal validity tracking
- Linked to agent orchestration records

---

## Related Documentation

- `deployments/GITHUB_RUNNER_DOCKER_COMPOSE.yml` - Docker Compose runner configuration
- `deployments/GITHUB_RUNNER_SETUP_CHECKLIST.md` - Initial runner setup
- `deployments/GITHUB_RUNNER_DEPLOYMENT_PLAN.md` - Detailed deployment guide
- `personal-hq/AGENTS.md` - Multi-agent orchestration system
- `personal-hq/CLAUDE.md` - Device and environment setup
- `context-hq` - Contextual information repository

---

## Quick Reference

### Hetzner Workflow
```bash
gh workflow run run-terminal-command-hetzner.yml \
  -f command="<command>" \
  -f runner_label="self-hosted,linux,x64,hetzner" \
  -f use_parallel=false \
  -f log_level=info
```

### MacBook Workflow
```bash
gh workflow run run-terminal-command-macbook.yml \
  -f command="<command>" \
  -f runner_label="self-hosted,macos,macbook" \
  -f shell_type=bash \
  -f upload_to_hetzner=true \
  -f log_level=info
```

### View Results
```bash
# Latest workflow run
gh run list --workflow run-terminal-command-hetzner.yml --limit 1

# View specific run
gh run view <run-id> --log

# Download artifacts
gh run download <run-id> --name hetzner-execution-logs
```

---

**Document Status:** Ready for use  
**Next Update:** After first production run  
**Last Verified:** December 17, 2025
