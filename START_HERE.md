# 👋 START HERE - GitHub HQ Quick Start

**Welcome to GitHub HQ!**

You have a fully-functional AI-powered GitHub workflow automation system ready to use.

---

## ⏱️ 15-Minute Setup

### Step 1: Get Your API Keys (5 min)

1. **Anthropic API Key**
   - Go to https://console.anthropic.com
   - Create new API key
   - Copy it (you'll need it soon)

2. **GitHub Token** (you may already have one)
   - Go to https://github.com/settings/tokens
   - Create new token with `repo` scope
   - Copy it

### Step 2: Configure Environment (3 min)

```bash
# Copy the template
cp .env.example .env

# Edit with your values
open .env  # or use your favorite editor
# (Add your ANTHROPIC_API_KEY and GITHUB_TOKEN)
```

### Step 3: Add GitHub Secrets (2 min)

```bash
# Add your API key to GitHub
gh secret set ANTHROPIC_API_KEY --body "paste_your_key_here"

# Verify it was added
gh secret list
```

### Step 4: Install Dependencies (3 min)

```bash
# Install npm packages
npm install

# Verify installation
npm list
```

### Step 5: Run Your First Agent (2 min)

```bash
# Make sure .env is sourced
set -a && source .env && set +a

# Run the agent
node scripts/agent-runner.js "List all files in this repository"
```

**That's it! You should see the agent execute your task!**

---

## 🎯 What You Can Do Now

### Local Execution
```bash
# Run any task locally
node scripts/agent-runner.js "Your task here"
```

### GitHub Actions
```bash
# Trigger via GitHub Actions
gh workflow run agent-basic.yml -F task="Your task"

# View execution
gh run list
```

### Monitoring
```bash
# Watch execution in real-time
./scripts/monitor-agent.sh
```

---

## 📚 Documentation

### Next: Read These (in order)

1. **SETUP_SUMMARY.md** ← Full setup guide (10 min read)
2. **PROJECT_README.md** ← Complete reference (20 min read)
3. **QUICKSTART.md** ← Implementation guide (30 min read)

### Then: Explore

- `.github/workflows/` - See the workflows
- `scripts/` - Examine the scripts
- `package.json` - Check dependencies

---

## 🚀 Common First Tasks

### Generate Documentation
```bash
node scripts/agent-runner.js \
  "Analyze this entire repository and generate comprehensive documentation"
```

### List Project Structure
```bash
node scripts/agent-runner.js \
  "Create a detailed file tree of this repository with descriptions"
```

### Code Analysis
```bash
node scripts/agent-runner.js \
  "Review all code in this repository for improvements and security issues"
```

### Create a Manifest
```bash
node scripts/agent-runner.js \
  "Create a manifest.json file listing all important files and their purposes"
```

---

## ❓ Common Questions

**Q: Where are my API keys stored?**  
A: In `.env` locally and GitHub Secrets for workflows. Never in code!

**Q: Can I run this on my computer?**  
A: Yes! Local execution works immediately. Just run the node command.

**Q: How do I trigger from GitHub Actions?**  
A: Use `gh workflow run` command or click "Actions" tab in GitHub.

**Q: Can I use this with multiple VMs?**  
A: Yes! See setup-hetzner-vm.sh in scripts folder.

**Q: How do I debug if something fails?**  
A: Use `./scripts/debug-agent.sh <RUN_ID>` to analyze logs.

---

## 🔧 Quick Command Reference

```bash
# Run locally
node scripts/agent-runner.js "task"

# Make scripts executable
chmod +x scripts/*.sh

# Trigger workflow
gh workflow run agent-basic.yml -F task="task"

# Monitor execution
./scripts/monitor-agent.sh

# View workflow runs
gh run list
gh run view <RUN_ID> --log

# Download logs
gh run download <RUN_ID>

# Debug failed run
./scripts/debug-agent.sh <RUN_ID>
```

---

## 📋 Setup Verification

Before continuing, verify:

- [ ] `.env` file exists and has API keys
- [ ] `npm install` completed successfully
- [ ] `gh` CLI is installed and authenticated
- [ ] Local agent execution works
- [ ] GitHub secrets are set

---

## ✅ You're Ready!

Your GitHub HQ is fully set up and ready to use.

### Next Action

Choose one:

**Option A - Keep Learning:**
```bash
cat SETUP_SUMMARY.md  # 10 min read
```

**Option B - Start Using:**
```bash
node scripts/agent-runner.js "Hello, GitHub HQ!"
```

**Option C - Explore Code:**
```bash
ls -la scripts/
cat .github/workflows/agent-basic.yml
```

---

## 🆘 Troubleshooting

### "command not found: gh"
→ Install GitHub CLI: https://cli.github.com

### "ANTHROPIC_API_KEY not set"
→ Check `.env` file exists: `ls -la .env`  
→ Load it: `set -a && source .env && set +a`

### "npm install fails"
→ Check Node version: `node --version` (need 20+)  
→ Clear cache: `npm cache clean --force`

### "Permission denied" on scripts
→ Make executable: `chmod +x scripts/*.sh`

### "GitHub workflow not visible"
→ Files must be in `.github/workflows/`  
→ Push changes: `git push`  
→ Refresh browser

---

## 📞 Support

1. **Check Documentation**
   - Read SETUP_SUMMARY.md
   - Read PROJECT_README.md

2. **Review Examples**
   - Look at `.github/workflows/`
   - Check `scripts/` folder

3. **Debug Issues**
   - Run `./scripts/debug-agent.sh <RUN_ID>`
   - Check `.env` file
   - Verify GitHub secrets

---

## 🎉 Welcome!

You're now part of the GitHub HQ ecosystem.

**Your first command to run:**

```bash
node scripts/agent-runner.js "Tell me about yourself"
```

**Then continue with:**

1. Read SETUP_SUMMARY.md
2. Run more complex tasks
3. Explore all features
4. Set up Hetzner VMs (optional)
5. Create custom workflows

---

## 🚀 Ready? Begin Here

```bash
# Verify environment
echo $ANTHROPIC_API_KEY
echo $GITHUB_TOKEN

# Run first agent
node scripts/agent-runner.js "What am I?"

# If that works, try GitHub Actions
gh workflow run agent-basic.yml -F task="Analyze repository"
```

---

**Status**: ✅ Ready to Use  
**Time to First Run**: 15 minutes  
**Difficulty**: Easy  
**Next Step**: Run your first agent!  

**Let's go!** 🚀
