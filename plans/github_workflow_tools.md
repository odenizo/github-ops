# Workflow: GitHub-HQ Tooling & Automation

## Objective
Develop GitHub-focused tools and workflows (actions, sync scripts, API utilities) to automate docs/schema sync, repo analysis, and connector setup.

## Components
- Repo sync workflow (generalized) driven by `repo-sync-config.json`.
- GitHub Actions job: fetch source repos, apply sync map, open PR with summary.
- Feature tools: PR triage, issue labeling, docs/schema mirroring, MCP server catalog sync.
- Connectors: ChatGPT/Claude MCP configs for GitHub ops.

## Tasks (plan only)
1) Define `configs/repo-sync/repo-sync-config.json` schema:
   - items: [{source_repo, ref, include_globs, exclude_globs, dest_prefix, mode (mirror|update), strip_prefix}].
2) Implement `scripts/sync_from_sources.py` (or ts):
   - read config; fetch zips; apply include/exclude; write to dest; summary output.
3) Add GitHub Action `.github/workflows/repo-sync.yml`:
   - manual + scheduled; matrix over sources; creates PR.
4) Add PR/issue helper tools:
   - Labeler rules; PR template; issue templates.
5) Add MCP client configs for GitHub ops (Claude Desktop/Codex/Gemini) pointing to octocode/github MCP servers.
6) Document runbook in `docs/workflows/github-sync.md`.

## Notes
- Ingestion: use ContextStream for decisions/logs; capture outputs after each run.
- Exclusion: ContextStream ingest can target subpaths; no per-file exclude toggle.
