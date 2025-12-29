# GitHub HQ - AI-Powered Workflow Automation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Node.js 20+](https://img.shields.io/badge/Node.js-20+-green)
![Status](https://img.shields.io/badge/Status-Production%20Ready-blue)

GitHub HQ is a complete system for orchestrating AI-powered GitHub workflow automation using Claude/GPT-4 as coding agents with MCP (Model Context Protocol) servers and GitHub Actions.

## 🚀 Quick Start

### Prerequisites
- GitHub account with repository access
- GitHub Personal Access Token (PAT)
- Anthropic API key or OpenRouter equivalent
- Node.js 20+ installed
- `gh` CLI installed

### 5-Minute Setup

```bash
# 1. Authenticate with GitHub
gh auth login

# 2. Clone this repository
git clone <repo-url>
cd github-hq

# 3. Install dependencies
npm install

# 4. Set up environment
cp .env.example .env
# Edit .env with your API keys

# 5. Set GitHub secrets
gh secret set ANTHROPIC_API_KEY --body "your_key_here"
gh secret set GITHUB_TOKEN --body "your_token_here"

# 6. Run your first agent
npm start "List all files in this repository"

# 7. Or trigger a workflow
gh workflow run agent-basic.yml -F task="Your task here"
```

## 📋 What's Included

### Scripts
- **agent-runner.js** - Core agent execution engine (Claude + MCP tools)
- **run-agent.sh** - Trigger and monitor agent workflows
- **monitor-agent.sh** - Real-time execution monitoring
- **debug-agent.sh** - Download and analyze execution logs
- **setup-hetzner-vm.sh** - Configure Hetzner VMs for remote execution

### Workflows
- **agent-basic.yml** - Basic single-task execution
- **agent-batch.yml** - Parallel batch task execution

### Configuration
- **package.json** - Node.js dependencies
- **.env.example** - Environment variable template
- **.gitignore** - Ignore sensitive files

## 🏗️ Architecture

```
User Input
    ↓
GitHub CLI / Actions
    ↓
Coding Agent (Claude/GPT-4)
    ↓
  MCP Tools  ← File I/O, Shell Exec, Git, GitHub API
    ↓
Execution   ← Local / GitHub Actions / Hetzner VM
    ↓
Results    → Repository / Artifacts / Issues / PRs
```

## 🔧 Available Tools

The agent has access to these MCP tools:

### Core Tools
- **execute_shell** - Run shell commands
- **read_file** - Read file contents
- **write_file** - Create/modify files
- **list_files** - List directory contents

### Extensible
- Add custom tools by extending `scripts/agent-runner.js`
- Define new tools with JSON schemas
- Execute any Node.js code

## 📚 Usage Examples

### Local Execution

```bash
# Run agent locally
node scripts/agent-runner.js "Generate API documentation"

# With shell script wrapper
./scripts/run-agent.sh "Create comprehensive README"

# Monitor execution
./scripts/monitor-agent.sh 5  # Refresh every 5 seconds
```

### GitHub Actions

```bash
# Trigger workflow manually
gh workflow run agent-basic.yml \
  -F task="Analyze code and suggest improvements" \
  -F model="claude-3-5-sonnet-20241022"

# View workflow status
gh run list
gh run view <RUN_ID> --log
```

### Batch Execution

```bash
# Run multiple tasks in parallel
gh workflow run agent-batch.yml \
  -F tasks_json='["Task 1", "Task 2", "Task 3"]'
```

### Hetzner VM Execution

```bash
# Setup VM
./scripts/setup-hetzner-vm.sh 1.2.3.4 ~/.ssh/hetzner_key ubuntu

# Add to GitHub secrets
gh secret set HETZNER_VM_IP --body "1.2.3.4"
gh secret set HETZNER_SSH_KEY --body "$(cat ~/.ssh/hetzner_key)"
```

## 🎯 Common Tasks

### Generate Documentation
```bash
node scripts/agent-runner.js "Analyze the codebase and generate comprehensive API documentation"
```

### Code Review
```bash
node scripts/agent-runner.js "Review the code for best practices, security issues, and optimization opportunities"
```

### Automated Testing
```bash
node scripts/agent-runner.js "Write unit tests for all exported functions"
```

### File Management
```bash
node scripts/agent-runner.js "Organize all image files into an assets directory with proper naming"
```

## 🔐 Security

### Best Practices
- ✅ Store API keys in GitHub Secrets, never in code
- ✅ Use fine-grained Personal Access Tokens
- ✅ Restrict workflow permissions
- ✅ Enable 2FA on GitHub account
- ✅ Rotate credentials regularly

### Never
- ❌ Commit `.env` files
- ❌ Log API keys
- ❌ Share SSH private keys
- ❌ Run untrusted code
- ❌ Use `sudo` in workflows without reason

## 🚀 Production Deployment

### Single VM
1. Set up Hetzner VM
2. Configure SSH key
3. Deploy MCP server
4. Update GitHub secrets
5. Enable workflows

### Multi-VM
1. Create multiple VMs
2. Configure SSH for each
3. Deploy MCP servers
4. Set up load balancing
5. Use matrix strategies in workflows

## 📊 Monitoring

### View Execution History
```bash
gh run list --limit 20
```

### Real-Time Monitoring
```bash
./scripts/monitor-agent.sh
```

### Download Logs
```bash
gh run download <RUN_ID>
```

### Debug Failed Runs
```bash
./scripts/debug-agent.sh <RUN_ID>
```

## 🔄 Workflow Triggers

### Manual
```bash
gh workflow run agent-basic.yml -F task="Your task"
```

### Scheduled
```yaml
on:
  schedule:
    - cron: '0 9 * * MON'  # Every Monday at 9 AM
```

### On Push
```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'scripts/**'
```

### On Pull Request
```yaml
on:
  pull_request:
    types: [opened, synchronize]
```

## 🛠️ Customization

### Add New Tools

Edit `scripts/agent-runner.js`:

```javascript
const tools = [
  {
    name: "my_tool",
    description: "My custom tool",
    input_schema: {
      type: "object",
      properties: {
        param: { type: "string" }
      },
      required: ["param"]
    }
  }
];
```

### Custom System Prompts

Create `prompts/custom-prompt.txt` with your system prompt:

```
You are an expert software engineer specializing in...
```

Then reference in workflows or scripts.

### Environment Variables

All available in `.env.example`:

```bash
AGENT_MODEL=claude-3-5-sonnet-20241022
AGENT_MAX_ITERATIONS=20
AGENT_TIMEOUT=300
```

## 📖 Documentation

Comprehensive documentation in this repository:

- **QUICKSTART.md** - 30-minute setup guide
- **github-hq-mcp-integration-guide.md** - Complete architecture
- **MCP-IMPLEMENTATION-REFERENCE.md** - Technical reference
- **IMPLEMENTATION-SCRIPTS.md** - All available scripts
- **IMPLEMENTATION_CHECKLIST.md** - 14-phase implementation guide

## 🐛 Troubleshooting

### "API key not found"
```bash
gh secret set ANTHROPIC_API_KEY --body "your_key"
```

### SSH Connection Failed
```bash
ssh -i ~/.ssh/hetzner_key ubuntu@<VM_IP>
ls -la ~/.ssh/hetzner_key  # Check permissions (should be 600)
```

### Workflow Not Triggering
- Check workflow file is in `.github/workflows/`
- Verify branch is correct
- Check workflow is enabled
- Ensure required secrets are set

### Agent Timeout
- Increase `timeout-minutes` in workflow
- Break complex task into subtasks
- Use Hetzner VM for resource-intensive tasks

## 📈 Performance Tips

1. **Use batch execution** for multiple independent tasks
2. **Cache dependencies** in workflows
3. **Parallelize with matrix** strategy
4. **Use Hetzner** for heavy computation
5. **Optimize prompts** for faster decisions

## 🤝 Contributing

Contributions welcome! Please:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details

## 📞 Support

For issues or questions:

1. Check [QUICKSTART.md](./QUICKSTART.md)
2. Review [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)
3. Check GitHub Issues
4. View workflow logs with `gh run view <ID> --log`

## 🌟 Features

✅ AI-powered automation (Claude/GPT-4)  
✅ Model Context Protocol (MCP) integration  
✅ GitHub Actions workflow automation  
✅ Local and remote execution  
✅ Real-time monitoring and logging  
✅ Multi-VM orchestration ready  
✅ Custom tool integration  
✅ Production-grade security  
✅ Comprehensive documentation  
✅ Copy-paste ready scripts  

## 🎯 Quick Links

- [GitHub Repository](https://github.com/odenizo/github-hq)
- [Issues](https://github.com/odenizo/github-hq/issues)
- [Discussions](https://github.com/odenizo/github-hq/discussions)
- [Anthropic Docs](https://docs.anthropic.com)
- [MCP Protocol](https://modelcontextprotocol.io)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Last Updated**: December 2024  

**Ready to automate? Start with `npm start` or `./scripts/run-agent.sh`**
