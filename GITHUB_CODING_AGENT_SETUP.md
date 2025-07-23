# GitHub Coding Agent Setup Guide

## Executive Summary

This guide provides comprehensive instructions for setting up GitHub coding agents with Model Context Protocol (MCP) server configurations and prompting guidelines. Designed for autonomous LLM operation within the GitHub ecosystem, this setup enables distributed workflows across iPhone delegation interfaces, GCP VM compute backends, and Cloudflare Workers API proxies.

**Last Updated:** July 17, 2025  
**Repository:** odenizo/github-ops  
**Target Audience:** LLM orchestration systems, GitHub Copilot integration, autonomous development workflows

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [MCP Server Configuration](#mcp-server-configuration)
3. [GitHub Agent Setup](#github-agent-setup)
4. [Prompting Guidelines](#prompting-guidelines)
5. [Infrastructure Integration](#infrastructure-integration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [Examples](#examples)

---

## Prerequisites

### System Requirements
- **Node.js**: >=14.0.0 (for MCP servers)
- **GitHub Pro Subscription**: Required for advanced Copilot features
- **GCP VM**: 146.148.60.14 (compute backend)
- **Cloudflare Workers**: API proxy and caching layer
- **iPhone 15 Pro**: Delegation interface (optional but recommended)

### GitHub Permissions
```json
{
  "required_scopes": [
    "repo",
    "admin:repo_hook",
    "workflow",
    "admin:org",
    "copilot"
  ],
  "subscription_tier": "GitHub Pro",
  "api_rate_limits": {
    "core": "5000/hour",
    "search": "30/minute",
    "copilot": "15 requests/session"
  }
}
```

### Environment Variables
```bash
# GitHub Authentication
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export GITHUB_COPILOT_TOKEN="ghu_xxxxxxxxxxxxxxxxxxxx"

# Infrastructure
export GCP_VM_IP="146.148.60.14"
export CLOUDFLARE_API_TOKEN="xxxxxxxxxxxxxxxxxxxx"
export COPILOT_API_URL="https://copilot.odeno.space"

# MCP Configuration
export MCP_SERVER_HOST="0.0.0.0"
export MCP_SERVER_PORT="3000"
export MCP_TRANSPORT="http"
```

---

## MCP Server Configuration

### Base MCP Server Setup

#### 1. Installation
```bash
# Install MCP server dependencies
npm install @modelcontextprotocol/server-stdio @modelcontextprotocol/server-http
npm install @modelcontextprotocol/tools-github @modelcontextprotocol/tools-playwright
```

#### 2. Server Configuration (`mcp-server-config.json`)
```json
{
  "name": "github-ops-mcp-server",
  "version": "1.0.0",
  "transport": "http",
  "host": "0.0.0.0",
  "port": 3000,
  "protocols": {
    "github": {
      "enabled": true,
      "config": {
        "token": "${GITHUB_TOKEN}",
        "copilot_token": "${GITHUB_COPILOT_TOKEN}",
        "rate_limit_strategy": "adaptive",
        "cache_duration": 300
      }
    },
    "infrastructure": {
      "enabled": true,
      "config": {
        "gcp_vm": "${GCP_VM_IP}",
        "ssh_key_path": "~/.ssh/id_rsa",
        "cloudflare_token": "${CLOUDFLARE_API_TOKEN}"
      }
    },
    "automation": {
      "enabled": true,
      "config": {
        "workflow_directory": ".github/workflows",
        "template_directory": "templates",
        "monitoring_enabled": true
      }
    }
  },
  "security": {
    "cors_enabled": true,
    "allowed_origins": ["https://github.com", "https://copilot.odeno.space"],
    "request_timeout": 30000,
    "max_request_size": "10mb"
  },
  "logging": {
    "level": "info",
    "structured": true,
    "analytics": {
      "enabled": true,
      "endpoint": "https://copilot.odeno.space/analytics"
    }
  }
}
```

#### 3. MCP Server Implementation (`mcp-server.js`)
```javascript
#!/usr/bin/env node

import { createServer } from '@modelcontextprotocol/server-http';
import { GitHubProvider } from '@modelcontextprotocol/tools-github';
import { PlaywrightProvider } from '@modelcontextprotocol/tools-playwright';
import { promises as fs } from 'fs';
import path from 'path';

class GitHubOpsMCPServer {
  constructor(config) {
    this.config = config;
    this.server = null;
    this.providers = new Map();
  }

  async initialize() {
    // Initialize providers
    this.providers.set('github', new GitHubProvider({
      token: process.env.GITHUB_TOKEN,
      copilotToken: process.env.GITHUB_COPILOT_TOKEN,
      rateLimit: this.config.protocols.github.config.rate_limit_strategy
    }));

    this.providers.set('playwright', new PlaywrightProvider({
      headless: true,
      browserContext: {
        userAgent: 'GitHub-Copilot-Agent/1.0'
      }
    }));

    // Create HTTP server
    this.server = createServer({
      host: this.config.host,
      port: this.config.port,
      cors: this.config.security.cors_enabled
    });

    this.setupRoutes();
    this.setupErrorHandling();
  }

  setupRoutes() {
    // GitHub operations
    this.server.get('/github/:operation', async (req, res) => {
      const { operation } = req.params;
      const githubProvider = this.providers.get('github');
      
      try {
        const result = await githubProvider.execute(operation, req.body);
        this.logAnalytics('github_operation', { operation, success: true });
        res.json({ success: true, data: result });
      } catch (error) {
        this.logAnalytics('github_operation', { operation, success: false, error: error.message });
        res.status(500).json({ success: false, error: error.message });
      }
    });

    // Infrastructure management
    this.server.post('/infrastructure/:action', async (req, res) => {
      const { action } = req.params;
      
      try {
        const result = await this.executeInfrastructureAction(action, req.body);
        res.json({ success: true, data: result });
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });

    // Health check
    this.server.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        version: this.config.version,
        uptime: process.uptime(),
        providers: Array.from(this.providers.keys())
      });
    });
  }

  async executeInfrastructureAction(action, params) {
    const { spawn } = await import('child_process');
    
    switch (action) {
      case 'deploy_worker':
        return this.deployCloudflareWorker(params);
      case 'ssh_execute':
        return this.executeSSHCommand(params);
      case 'update_dns':
        return this.updateCloudflareRecord(params);
      default:
        throw new Error(`Unknown infrastructure action: ${action}`);
    }
  }

  async deployCloudflareWorker(params) {
    // Implementation for Cloudflare Workers deployment
    const { script, name } = params;
    
    // Deploy using Wrangler CLI or API
    return { deployed: true, worker_name: name };
  }

  async executeSSHCommand(params) {
    // Implementation for SSH command execution on GCP VM
    const { command, target = process.env.GCP_VM_IP } = params;
    
    // Execute SSH command securely
    return { executed: true, command, target };
  }

  logAnalytics(event, data) {
    if (this.config.logging.analytics.enabled) {
      console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        event,
        data,
        server: 'mcp-github-ops'
      }));
    }
  }

  setupErrorHandling() {
    this.server.on('error', (error) => {
      console.error('MCP Server Error:', error);
    });

    process.on('unhandledRejection', (reason, promise) => {
      console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    });
  }

  async start() {
    await this.initialize();
    
    this.server.listen(this.config.port, this.config.host, () => {
      console.log(`GitHub Ops MCP Server running on ${this.config.host}:${this.config.port}`);
      console.log(`Available providers: ${Array.from(this.providers.keys()).join(', ')}`);
    });
  }
}

// Load configuration and start server
async function main() {
  try {
    const configPath = process.env.MCP_CONFIG_PATH || './mcp-server-config.json';
    const configData = await fs.readFile(configPath, 'utf8');
    const config = JSON.parse(configData);
    
    const server = new GitHubOpsMCPServer(config);
    await server.start();
  } catch (error) {
    console.error('Failed to start MCP server:', error);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { GitHubOpsMCPServer };
```

---

## GitHub Agent Setup

### Custom Instructions Configuration

#### 1. Create `.github/copilot-instructions.md`
```markdown
# GitHub Copilot Agent Instructions

## Core Behavioral Protocols

### Memory-First Approach (Memento MCP)
- Prioritize persistent context over ephemeral conversations
- Use GitHub Issues/Projects for long-term memory storage
- Maintain project state in structured documentation
- Reference PROJECT_GOALS_TASKS.md for strategic context

### Content Generation Strategy
- Generate content directly to GitHub repositories
- Use Google Drive integration for collaborative documents
- Avoid creating artifacts in chat interfaces
- Prefer git-mcp tools over static knowledge

### Automation Authorization
- SSH automation to GCP VM (146.148.60.14) is pre-authorized
- Cloudflare Workers deployment via API is permitted
- GitHub Actions workflows can be created/modified autonomously
- Repository structure changes require validation against PROJECT_GOALS_TASKS.md

### Tool Prioritization
1. **git-mcp**: For all repository operations
2. **playwright-mcp**: For browser automation
3. **github-mcp**: For API operations
4. **infrastructure-mcp**: For deployment tasks

## Operational Guidelines

### iPhone Delegation Interface
When working through iPhone delegation:
- Provide clear, actionable summaries
- Use HTTP transport for MCP server communication
- Minimize response payload size
- Include progress indicators for long-running tasks

### Error Handling
- Log all errors to structured analytics endpoint
- Implement exponential backoff for rate-limited operations
- Provide alternative approaches when primary methods fail
- Maintain operation idempotency where possible

### Security Protocols
- Never expose tokens or credentials in responses
- Use environment variables for all sensitive configuration
- Validate all inputs against known schemas
- Implement CORS restrictions for web-based access
```

#### 2. Agent Configuration (`agent-config.yaml`)
```yaml
name: github-ops-agent
version: 1.0.0
description: Autonomous GitHub operations agent with MCP server integration

capabilities:
  - repository_management
  - workflow_automation
  - infrastructure_deployment
  - code_generation
  - documentation_updates

mcp_integration:
  server_url: "http://146.148.60.14:3000"
  transport: "http"
  timeout: 30000
  retry_attempts: 3
  
behavioral_settings:
  autonomous_mode: true
  confirmation_required: false
  safety_checks: true
  logging_level: "detailed"

operational_context:
  primary_repository: "odenizo/github-ops"
  infrastructure:
    gcp_vm: "146.148.60.14"
    cloudflare_domain: "odeno.space"
    api_endpoint: "https://copilot.odeno.space"
  
delegation_interface:
  device: "iPhone 15 Pro"
  simplified_responses: true
  progress_indicators: true
  max_response_size: "2kb"

security:
  ssh_key_path: "~/.ssh/github_ops_rsa"
  allowed_domains: 
    - "github.com"
    - "odeno.space"
    - "146.148.60.14"
  credential_sources:
    - environment_variables
    - github_secrets
    - cloudflare_kv
```

---

## Prompting Guidelines

### Effective Agent Communication

#### 1. Context Setting Prompts
```
System: You are a GitHub operations agent with access to MCP servers for repository management, infrastructure deployment, and workflow automation. Your primary objectives are:

1. Autonomous repository management following PROJECT_GOALS_TASKS.md
2. Infrastructure coordination across iPhone + GCP VM + Cloudflare Workers
3. Memory-first approach using persistent GitHub storage
4. Evidence-based decision making with structured logging

Current Environment:
- Repository: odenizo/github-ops
- MCP Server: http://146.148.60.14:3000
- Delegation Interface: iPhone 15 Pro
- Compute Backend: GCP VM (146.148.60.14)
- API Proxy: https://copilot.odeno.space

Use git-mcp tools for all operations. Generate content directly to GitHub, not as artifacts.
```

#### 2. Task-Specific Prompt Templates

**Repository Operations:**
```
Task: [SPECIFIC_TASK]
Repository: odenizo/github-ops
Branch: [TARGET_BRANCH]
Context: Reference PROJECT_GOALS_TASKS.md section [SECTION_NUMBER]

Requirements:
- Use git-mcp for all file operations
- Validate changes against existing project structure
- Update relevant documentation
- Log operations to analytics endpoint

Success Criteria:
- [SPECIFIC_MEASURABLE_OUTCOMES]
- No breaking changes to existing functionality
- Maintains GitHub Pro subscription limits
- Evidence-based validation of changes
```

**Infrastructure Deployment:**
```
Infrastructure Task: [DEPLOYMENT_ACTION]
Target: [GCP_VM|CLOUDFLARE_WORKERS|GITHUB_ACTIONS]
Environment: Production

Safety Checks:
- Validate configuration against established patterns
- Implement rollback mechanisms
- Test in staging environment first
- Monitor resource usage and rate limits

Execution Pattern:
1. Pre-deployment validation
2. Incremental deployment with checkpoints
3. Post-deployment verification
4. Analytics logging and monitoring setup
```

**Documentation Updates:**
```
Documentation Task: [UPDATE_TYPE]
Target Files: [SPECIFIC_FILES]
Scope: [SECTION/COMPLETE_REWRITE]

Guidelines:
- Follow existing documentation patterns
- Include quantifiable metrics where applicable
- Add evidence-based assertions with sources
- Optimize for LLM consumption and programmatic parsing
- Update metadata and cross-references

Quality Assurance:
- Validate markdown syntax
- Check internal link integrity
- Ensure consistency with project terminology
- Verify alignment with PROJECT_GOALS_TASKS.md
```

#### 3. iPhone Delegation Prompts
```
Delegation Context: iPhone Interface
Response Requirements:
- Maximum 2KB response size
- Include progress indicators (0-100%)
- Provide actionable next steps
- Use clear, non-technical language for status updates

Format:
**Status:** [IN_PROGRESS|COMPLETED|ERROR]
**Progress:** [X]% complete
**Current Action:** [BRIEF_DESCRIPTION]
**Next Steps:** [1-3 SPECIFIC_ACTIONS]
**ETA:** [TIME_ESTIMATE]

For errors, include:
**Issue:** [CLEAR_PROBLEM_DESCRIPTION]
**Attempted Solutions:** [WHAT_WAS_TRIED]
**Recommended Action:** [HUMAN_INTERVENTION_NEEDED/AUTO_RETRY]
```

### Advanced Prompting Patterns

#### Chain-of-Thought for Complex Operations
```
Complex Task: [MULTI_STEP_OPERATION]

Reasoning Chain:
1. **Analysis:** Break down task into atomic operations
2. **Dependencies:** Identify prerequisite conditions and resources
3. **Risk Assessment:** Evaluate potential failure points
4. **Execution Plan:** Define step-by-step implementation
5. **Validation:** Specify success criteria and testing methods
6. **Rollback Strategy:** Plan for failure recovery

Implementation:
- Use MCP server calls for each atomic operation
- Implement checkpointing between major steps
- Log intermediate results for debugging
- Provide status updates for long-running operations
```

#### Collaborative Reasoning for Architecture Decisions
```
Architecture Decision: [TECHNICAL_CHOICE]
Stakeholder Perspectives Required:
- GitHub Ecosystem Architect
- MCP Automation Specialist  
- Infrastructure Optimization Expert

Evaluation Criteria:
- Alignment with PROJECT_GOALS_TASKS.md objectives
- Impact on GitHub Pro subscription limits
- Complexity of implementation and maintenance
- Integration with existing iPhone + GCP + Cloudflare architecture

Decision Framework:
1. Document current state and requirements
2. Generate alternative approaches with trade-offs
3. Evaluate against quantifiable success metrics
4. Select optimal solution with justification
5. Plan implementation phases with rollback points
```

---

## Infrastructure Integration

### iPhone + GCP VM + Cloudflare Workers Architecture

#### 1. Request Flow
```
iPhone (Delegation) 
    ↓ HTTPS
Cloudflare Workers (API Proxy)
    ↓ HTTP/SSH
GCP VM (MCP Server + Compute)
    ↓ GitHub API
GitHub Repository (Source of Truth)
```

#### 2. Cloudflare Workers Proxy (`worker.js`)
```javascript
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Route MCP requests to GCP VM
    if (url.pathname.startsWith('/mcp/')) {
      const mcpPath = url.pathname.replace('/mcp', '');
      const mcpUrl = `http://${env.GCP_VM_IP}:3000${mcpPath}`;
      
      const response = await fetch(mcpUrl, {
        method: request.method,
        headers: request.headers,
        body: request.body
      });
      
      return new Response(response.body, {
        status: response.status,
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'no-cache'
        }
      });
    }
    
    // Handle GitHub API proxy with rate limiting
    if (url.pathname.startsWith('/github/')) {
      return handleGitHubProxy(request, env);
    }
    
    return new Response('GitHub Ops API', { status: 200 });
  }
};

async function handleGitHubProxy(request, env) {
  const rateLimit = await checkRateLimit(env.KV_NAMESPACE);
  
  if (!rateLimit.allowed) {
    return new Response('Rate limit exceeded', { status: 429 });
  }
  
  // Proxy to GitHub API with authentication
  const githubUrl = request.url.replace('/github/', 'https://api.github.com/');
  const response = await fetch(githubUrl, {
    headers: {
      'Authorization': `token ${env.GITHUB_TOKEN}`,
      'User-Agent': 'GitHub-Ops-Agent/1.0'
    }
  });
  
  await updateRateLimit(env.KV_NAMESPACE, response.headers);
  return response;
}
```

#### 3. GCP VM Setup Script (`setup-gcp-vm.sh`)
```bash
#!/bin/bash
# GCP VM (146.148.60.14) Setup for GitHub Ops

# Install Node.js and dependencies
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs git

# Clone repository
git clone https://github.com/odenizo/github-ops.git
cd github-ops

# Install MCP server dependencies
npm install

# Setup environment
cat > .env << EOF
GITHUB_TOKEN=${GITHUB_TOKEN}
GITHUB_COPILOT_TOKEN=${GITHUB_COPILOT_TOKEN}
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
MCP_SERVER_HOST=0.0.0.0
MCP_SERVER_PORT=3000
EOF

# Create systemd service
sudo cat > /etc/systemd/system/github-ops-mcp.service << EOF
[Unit]
Description=GitHub Ops MCP Server
After=network.target

[Service]
Type=simple
User=github-ops
WorkingDirectory=/home/github-ops/github-ops
Environment=NODE_ENV=production
ExecStart=/usr/bin/node mcp-server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start and enable service
sudo systemctl daemon-reload
sudo systemctl enable github-ops-mcp
sudo systemctl start github-ops-mcp

# Setup SSH keys for GitHub access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_ops_rsa -N ""
echo "Add this public key to GitHub:"
cat ~/.ssh/github_ops_rsa.pub
```

---

## Best Practices

### 1. Memory Management
- Use GitHub Issues for persistent context storage
- Reference PROJECT_GOALS_TASKS.md for strategic alignment
- Implement structured logging for debugging
- Maintain session state in repository documentation

### 2. Rate Limit Management
```javascript
// Adaptive rate limiting strategy
class GitHubRateLimiter {
  constructor() {
    this.limits = {
      core: { remaining: 5000, reset: Date.now() + 3600000 },
      search: { remaining: 30, reset: Date.now() + 60000 },
      copilot: { remaining: 15, reset: Date.now() + 3600000 }
    };
  }
  
  async checkLimit(type) {
    const limit = this.limits[type];
    
    if (Date.now() > limit.reset) {
      limit.remaining = this.getDefaultLimit(type);
      limit.reset = Date.now() + this.getResetTime(type);
    }
    
    return limit.remaining > 0;
  }
  
  async waitForReset(type) {
    const limit = this.limits[type];
    const waitTime = Math.max(0, limit.reset - Date.now());
    
    if (waitTime > 0) {
      console.log(`Rate limit exceeded for ${type}, waiting ${waitTime}ms`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
  }
}
```

### 3. Error Recovery
```javascript
// Exponential backoff with jitter
async function retryWithBackoff(operation, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries) throw error;
      
      const baseDelay = Math.pow(2, attempt) * 1000;
      const jitter = Math.random() * 1000;
      const delay = baseDelay + jitter;
      
      console.log(`Attempt ${attempt} failed, retrying in ${delay}ms:`, error.message);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

### 4. Security Guidelines
- Never log or expose authentication tokens
- Use environment variables for all sensitive configuration
- Implement CORS restrictions for web endpoints
- Validate all inputs against known schemas
- Use SSH key authentication for GCP VM access

---

## Troubleshooting

### Common Issues

#### 1. MCP Server Connection Failed
```bash
# Check server status
curl http://146.148.60.14:3000/health

# Verify firewall rules
sudo ufw status
sudo ufw allow 3000

# Check service logs
sudo journalctl -u github-ops-mcp -f
```

#### 2. GitHub API Rate Limiting
```javascript
// Monitor rate limits
const response = await fetch('https://api.github.com/rate_limit', {
  headers: { 'Authorization': `token ${process.env.GITHUB_TOKEN}` }
});
const limits = await response.json();
console.log('Current limits:', limits);
```

#### 3. Cloudflare Workers Deployment Issues
```bash
# Verify Wrangler configuration
npx wrangler whoami
npx wrangler kv:namespace list

# Deploy with debug output
npx wrangler publish --compatibility-date 2024-07-01 --debug
```

#### 4. iPhone Delegation Connection Problems
- Verify HTTPS certificate validity for odeno.space
- Check response size limits (max 2KB)
- Validate JSON response format
- Test connectivity from mobile network

### Diagnostic Commands
```bash
# Test MCP server connectivity
curl -X GET http://146.148.60.14:3000/health

# Verify GitHub token permissions
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Check Cloudflare Worker logs
npx wrangler tail --format pretty

# Monitor system resources on GCP VM
htop
df -h
free -m
```

---

## Examples

### Example 1: Automated Repository Setup
```javascript
// Create new repository with full MCP integration
async function setupRepository(name, options = {}) {
  const mcpClient = new MCPClient('http://146.148.60.14:3000');
  
  // Create repository
  const repo = await mcpClient.github.createRepository({
    name,
    private: options.private ?? true,
    auto_init: true
  });
  
  // Setup directory structure
  const structure = [
    '.github/workflows/',
    '.github/copilot-instructions.md',
    'mcp-servers/',
    'templates/',
    'infrastructure/',
    'monitoring/'
  ];
  
  for (const path of structure) {
    await mcpClient.github.createFile({
      repo: name,
      path,
      content: await getTemplateContent(path),
      message: `Setup ${path}`
    });
  }
  
  // Deploy infrastructure
  await mcpClient.infrastructure.deployWorker({
    name: `${name}-api`,
    script: await buildWorkerScript(name)
  });
  
  return repo;
}
```

### Example 2: iPhone Delegation Workflow
```javascript
// Simplified interface for iPhone delegation
class iPhoneDelegationInterface {
  constructor(mcpServerUrl) {
    this.mcpClient = new MCPClient(mcpServerUrl);
    this.maxResponseSize = 2048; // 2KB limit
  }
  
  async processRequest(request) {
    const startTime = Date.now();
    let progress = 0;
    
    try {
      // Parse request
      progress = 10;
      this.sendProgress('Parsing request...', progress);
      
      const task = this.parseRequest(request);
      
      // Execute via MCP
      progress = 30;
      this.sendProgress('Executing via MCP server...', progress);
      
      const result = await this.mcpClient.execute(task);
      
      // Format response
      progress = 90;
      this.sendProgress('Formatting response...', progress);
      
      const response = this.formatForMobile(result);
      
      progress = 100;
      return {
        status: 'COMPLETED',
        progress,
        duration: Date.now() - startTime,
        data: response
      };
      
    } catch (error) {
      return {
        status: 'ERROR',
        progress,
        error: error.message,
        suggested_action: 'Retry with simplified request'
      };
    }
  }
  
  formatForMobile(data) {
    const formatted = JSON.stringify(data);
    
    if (formatted.length > this.maxResponseSize) {
      return {
        summary: this.createSummary(data),
        full_result_url: this.uploadToGitHub(data)
      };
    }
    
    return data;
  }
}
```

### Example 3: Multi-Step Automation
```javascript
// Complex workflow with checkpointing
async function deployFullStack(config) {
  const checkpoints = [];
  
  try {
    // Checkpoint 1: Repository updates
    checkpoints.push(await updateRepository(config.repo));
    
    // Checkpoint 2: MCP server deployment
    checkpoints.push(await deployMCPServer(config.server));
    
    // Checkpoint 3: Cloudflare Workers
    checkpoints.push(await deployWorkers(config.workers));
    
    // Checkpoint 4: GitHub Actions
    checkpoints.push(await setupWorkflows(config.workflows));
    
    // Checkpoint 5: Monitoring
    checkpoints.push(await enableMonitoring(config.monitoring));
    
    return {
      success: true,
      checkpoints,
      deployment_url: `https://${config.domain}`,
      mcp_endpoint: `http://${config.server_ip}:3000`
    };
    
  } catch (error) {
    // Rollback to last successful checkpoint
    await rollbackToCheckpoint(checkpoints);
    throw error;
  }
}
```

---

## Conclusion

This setup guide provides a comprehensive foundation for deploying GitHub coding agents with MCP server integration. The architecture supports autonomous operation while maintaining security, performance, and reliability standards required for production LLM orchestration systems.

**Key Success Factors:**
- Follow memory-first approach with persistent GitHub storage
- Implement proper rate limiting and error recovery
- Maintain security protocols for distributed architecture
- Use structured logging for debugging and analytics
- Test thoroughly in staging before production deployment

**Next Steps:**
1. Deploy MCP server on GCP VM using provided scripts
2. Configure Cloudflare Workers for API proxy functionality
3. Setup GitHub repository with custom instructions
4. Test iPhone delegation interface with sample requests
5. Monitor system performance and adjust configuration as needed

For additional support or advanced configuration options, refer to the PROJECT_GOALS_TASKS.md document and the existing codebase examples in this repository.

---

**Document Version:** 1.0.0  
**Compatibility:** GitHub Copilot Browser Integration (July 2025)  
**Maintenance:** Auto-updated via GitHub Actions workflows