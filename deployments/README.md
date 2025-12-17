# GitHub Operations Deployments

Production deployment plans and configurations for GitHub-related infrastructure.

## Contents

### GitHub Runner Deployment (NEW)

Comprehensive self-hosted runner deployment for Hetzner VM with 1Panel integration.

#### Quick Links
- 📋 **[GITHUB_RUNNER_DEPLOYMENT_PLAN.md](./GITHUB_RUNNER_DEPLOYMENT_PLAN.md)** - Complete architecture, strategy, and 10-phase implementation plan
- ✅ **[GITHUB_RUNNER_SETUP_CHECKLIST.md](./GITHUB_RUNNER_SETUP_CHECKLIST.md)** - Step-by-step implementation checklist with verification
- 🐳 **[GITHUB_RUNNER_DOCKER_COMPOSE.yml](./GITHUB_RUNNER_DOCKER_COMPOSE.yml)** - Production-ready docker-compose configuration

#### Quick Start (5 steps)

```bash
# 1. Get your GitHub PAT token
# Visit: https://github.com/settings/tokens
# Scopes: repo, admin:org_hook, admin:self_hosted_runner

# 2. Generate runner registration tokens
# Visit: https://github.com/odenizo/[REPO]/settings/actions/runners/new

# 3. Set up directories on Hetzner
ssh hetz
sudo mkdir -p /opt/github-runners/docker-compose
cd /opt/github-runners/docker-compose

# 4. Copy configuration files
cp GITHUB_RUNNER_DOCKER_COMPOSE.yml docker-compose.yml
cat > .env << 'EOF'
GITHUB_PAT=ghp_your_token_here
RUNNER_TOKEN_1=your_token_1
RUNNER_TOKEN_2=your_token_2
EOF
chmod 600 .env

# 5. Deploy and verify
sudo docker-compose up -d
sudo docker-compose ps
```

#### Key Specifications

**Hardware Allocation:**
- Runner 1: 4 CPU cores, 16GB RAM (primary build runner)
- Runner 2: 2 CPU cores, 8GB RAM (parallel jobs)
- Server: 12 CPU cores, 128GB RAM total (Hetzner Dedicated)

**Architecture:**
- Docker-based containerized runners
- Persistent registration (non-ephemeral)
- Docker-in-Docker support (DinD)
- Auto-restart on failure or server reboot
- Health checks every 10 seconds
- Port mappings: 8091, 8092 for monitoring

**1Panel Integration:**
- Available via 1Panel's container dashboard
- Can upload docker-compose via 1Panel UI
- Monitoring: CPU, memory, logs, restart status
- No native "GitHub Runner" app in app store yet

#### Implementation Timeline

| Phase | Time | Activity |
|-------|------|----------|
| 1 | 30 min | Preparation & token gathering |
| 2 | 1 hour | Directory setup & configuration |
| 3 | 30 min | Docker deployment |
| 4 | 1 hour | Testing & validation |
| 5 | 1 hour | 1Panel integration |
| **Total** | **~5 hours** | **Complete deployment** |

#### Performance Expectations

**vs GitHub Hosted Runners:**
- CPU: 2 cores → 12 cores available (6x improvement)
- RAM: 7GB → 128GB available (18x improvement)
- Build time: 5 min average → 1-2 min (60-80% faster)
- Cost: $0.008/min → Free (using existing server)
- Break-even: ~500 workflow minutes/month

#### Security Features

✅ Token management:
- PAT stored in encrypted .env (600 permissions)
- Not committed to version control
- Rotation schedule: 90 days

✅ Network isolation:
- Custom bridge network for runners
- Docker socket restricted to runners
- Resource limits prevent resource exhaustion

✅ Access control:
- Runners scoped to personal repositories
- Can be promoted to organization runners
- GitHub Actions workflow-level access control

#### Monitoring & Maintenance

**Health Checks:**
- Runner process monitoring (every 10 sec)
- Automatic restart on failure
- Docker daemon health verification
- Disk/memory usage tracking

**Maintenance:**
- Monthly cleanup of old workflow artifacts
- Quarterly PAT token rotation
- Yearly security audit
- Regular log review for anomalies

#### Troubleshooting

**Runner not connecting:**
```bash
ssh hetz
sudo docker logs github-runner-1 | tail -50
sudo docker exec github-runner-1 curl -I https://github.com
```

**High resource usage:**
```bash
sudo docker stats github-runner-1 github-runner-2
```

**Docker-in-Docker issues:**
```bash
sudo docker exec github-runner-1 docker ps
ls -la /var/run/docker.sock
```

See [GITHUB_RUNNER_DEPLOYMENT_PLAN.md](./GITHUB_RUNNER_DEPLOYMENT_PLAN.md#phase-10-troubleshooting-guide) for complete troubleshooting guide.

#### Related Documentation

- **[personal-hq](../README.md)** - Infrastructure overview
- **[hetzner-hq](../../hetzner-hq/README.md)** - Hetzner server configuration
- **[1Panel Documentation](https://1panel.io/docs/)** - Server management platform
- **[GitHub Actions Runner Docs](https://docs.github.com/en/actions/hosting-your-own-runners)** - Official GitHub reference

#### Key Decision Points

**Start with 2 runners or 3?**
- Recommended: 2 initially
- Add runner-3 if build queuing becomes issue
- Can scale to 4+ with additional resource allocation

**Ephemeral or persistent mode?**
- Recommended: Persistent (non-ephemeral)
- Simpler management and configuration
- Better for stable, long-running jobs

**When to add more runners?**
- Persistent job queue > 3 minutes
- CPU utilization > 80% consistently
- Multiple workflows scheduled to run together

#### Next Steps

1. **Review** - Read [GITHUB_RUNNER_DEPLOYMENT_PLAN.md](./GITHUB_RUNNER_DEPLOYMENT_PLAN.md)
2. **Prepare** - Gather GitHub tokens and SSH access
3. **Execute** - Follow [GITHUB_RUNNER_SETUP_CHECKLIST.md](./GITHUB_RUNNER_SETUP_CHECKLIST.md)
4. **Deploy** - Use [GITHUB_RUNNER_DOCKER_COMPOSE.yml](./GITHUB_RUNNER_DOCKER_COMPOSE.yml)
5. **Verify** - Confirm runners online in GitHub UI
6. **Integrate** - Add to existing workflows

---

### Other Deployments

#### 1Panel Installation
- Reference: [1PANEL_DEPLOYMENT_PLAN.md](./1PANEL_DEPLOYMENT_PLAN.md)
- Checklist: [1PANEL_INSTALLATION_CHECKLIST.md](./1PANEL_INSTALLATION_CHECKLIST.md)
- Status: ✅ Already deployed on Hetzner VM

#### System Architecture
- Full documentation: [FULL_SYSTEM_ARCHITECTURE.md](./FULL_SYSTEM_ARCHITECTURE.md)
- MCP servers: [MCP_SERVERS_PUBLIC_ONLY.md](./MCP_SERVERS_PUBLIC_ONLY.md)

---

## File Organization

```
deployments/
├── README.md                                 # This file
├── GITHUB_RUNNER_DEPLOYMENT_PLAN.md         # Complete strategy (new)
├── GITHUB_RUNNER_SETUP_CHECKLIST.md         # Implementation checklist (new)
├── GITHUB_RUNNER_DOCKER_COMPOSE.yml         # Docker config template (new)
├── 1PANEL_DEPLOYMENT_PLAN.md                # Existing 1Panel plan
├── 1PANEL_INSTALLATION_CHECKLIST.md         # Existing 1Panel checklist
├── FULL_SYSTEM_ARCHITECTURE.md              # System overview
├── MCP_SERVERS_PUBLIC_ONLY.md               # MCP integration
└── workflows/                               # Deployment workflow templates
    ├── template-deployment-workflow.md
    └── [additional workflow templates]
```

## Documentation Status

- ✅ GitHub Runner deployment: Complete
- ✅ 1Panel integration: Complete
- ✅ Architecture documentation: Complete
- ✅ Setup checklists: Complete
- ⏳ Ansible playbooks: Planned
- ⏳ Terraform configuration: Planned

## Contributing

When adding new deployment plans:

1. Follow the existing structure (Plan → Checklist → Config)
2. Include prerequisites and security considerations
3. Add troubleshooting guide
4. Reference existing infrastructure (hetzner-hq, personal-hq)
5. Update this README with links

## References

### Official Documentation
- [GitHub Actions Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [1Panel Server Management](https://1panel.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

### Public Reference Implementations
- [decentriq/hetzner-ci-setup](https://github.com/decentriq/hetzner-ci-setup) - GitHub Actions on Hetzner
- [myoung34/github-runner](https://hub.docker.com/r/myoung34/github-runner) - Docker image

### Internal References
- **[github-ops](../README.md)** - This repository
- **[personal-hq](../../personal-hq/README.md)** - Infrastructure hub
- **[hetzner-hq](../../hetzner-hq/README.md)** - Server configuration

---

**Last Updated:** 2025-12-17  
**Status:** Active  
**Maintainer:** Personal Infrastructure Team  
