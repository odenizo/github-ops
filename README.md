# github-ops

Comprehensive GitHub operations automation center for LLM orchestration, agent workflows, and GitHub Copilot ecosystem management. Designed for autonomous LLM operation and GitHub-based development automation.

## Features

### GitHub Docs Copilot Sync
Automatically syncs the latest GitHub Copilot documentation from the official [GitHub Docs](https://github.com/github/docs) repository to our local `docs/copilot/` directory.

- **Workflow**: [`.github/workflows/sync-github-docs-copilot.yml`](.github/workflows/sync-github-docs-copilot.yml)
- **Schedule**: Daily at 6 AM UTC
- **Manual Trigger**: Available via GitHub Actions interface
- **Target**: Syncs `github/docs/content/copilot/` → `docs/copilot/`

### GitHub Docs Indexer  
Tools for generating directory indexes of the GitHub/docs repository, optimized for LLM-based file lookup and content discovery.

- **Location**: [`github-docs-indexer/`](github-docs-indexer/)
- **Purpose**: Generate structured XML indexes for AI consumption
- **Usage**: `npm run generate` in the indexer directory
