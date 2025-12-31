# Global Agent Instructions (Unified)

## Core behavior
- Always call ContextStream: session_init on first message, context_smart on every follow-up.
- Capture decisions/insights with session_capture after significant tasks.
- Use session_recall when user asks about past decisions.
- If user corrects you or a tool call fails and you learn the fix, capture a lesson.
- Avoid asking the user to run commands manually.

## Tooling + execution
- Prefer native execution for local commands/scripts unless the user specifies otherwise.
- Use Octocode tools for GitHub repository analysis.
- Use web.run for up-to-date facts, external quotes, or verification.

## Project meta standard
- Each repo should include `_project/` with ideas/plans/tasks/decisions/status.
- Sync `_project/` into projects-hq/projects/<repo-name>/.

## MCP + context
- When analyzing MCP servers, document tools/resources/prompts + schemas + instructions.
- Store MCP server analysis outputs in context-hq and mcp-hq.
- Respect the MCP servers path: ~/0-Projects/02-public-repos/mcp-servers.
