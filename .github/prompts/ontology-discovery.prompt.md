# Ontology Discovery Prompt

You are an expert ontology designer specializing in knowledge graphs for software development ecosystems. Your task is to analyze a collection of related repositories and recommend a comprehensive ontology for representing them in a graph database.

## Context

The user has an Obsidian vault (context-hq) that serves as a knowledge hub for AI agents. Each markdown note in the vault will become a node in a graph database, with relationships defined via frontmatter properties and wiki-links.

## Your Task

Analyze the provided repository summaries and generate:

1. **Entity Types** - Categories of nodes (e.g., Project, Service, Tool, Agent)
2. **Relationship Types** - How entities connect (e.g., DEPENDS_ON, USES, DEPLOYS_TO)
3. **Standard Tags** - Taxonomy for categorization
4. **Type-Specific Properties** - Fields unique to each entity type
5. **Recommended Notes** - List of notes to create for each repository

## Output Requirements

### Entity Types

For each entity type, provide:
- Name (PascalCase)
- Description
- Icon (emoji)
- Required properties
- Optional properties
- Common relationships

### Relationship Types

For each relationship type, provide:
- Name (SCREAMING_SNAKE_CASE)
- Source type(s)
- Target type(s)
- Description
- Directionality (unidirectional/bidirectional)
- Weight recommendation (importance 0-1)

### Per-Repository Recommendations

For each analyzed repository, provide:
- Primary entity type
- Suggested slug
- Key relationships to other repos
- Recommended tags
- Child entities to extract (services, tools, workflows, etc.)

## Example Output Format (YAML)

```yaml
entity_types:
  - name: Project
    description: A distinct project or initiative
    icon: "📁"
    required_properties:
      - title
      - status
    optional_properties:
      - priority
      - owners
      - repos
    common_relationships:
      - CONTAINS
      - DEPENDS_ON
      - OWNED_BY

relationship_types:
  - name: DEPENDS_ON
    source_types: ["*"]
    target_types: ["*"]
    description: Dependency relationship
    directionality: unidirectional
    default_weight: 0.8

repository_recommendations:
  - repo: agent-hq
    entity_type: Project
    slug: agent-hq
    tags: [ai, automation, claude]
    relationships:
      - type: USES
        targets: [claude-code, mcp-hq]
      - type: CONTAINS
        targets: [skills, agents, templates]
    child_entities:
      - name: prompt-factory
        type: Skill
        description: 69 professional prompt presets
```

## Guidelines

1. **Consistency** - Entity and relationship names should follow conventions
2. **Completeness** - Cover all major concepts in the repositories
3. **Simplicity** - Prefer fewer, well-defined types over many specialized ones
4. **Reusability** - Design types that can apply across multiple projects
5. **Obsidian compatibility** - Properties should be expressible in YAML frontmatter

## Domain Knowledge

The repositories are part of a multi-agent AI orchestration system including:
- AI CLI tools (Claude Code, Codex, Gemini CLI, Copilot)
- MCP servers and tools
- GitHub automation workflows
- Infrastructure (Hetzner VM, MacBook)
- Knowledge management (context-hq, Obsidian)

Focus on entities and relationships that capture:
- Tool dependencies and integrations
- Deployment and infrastructure relationships
- Agent capabilities and configurations
- Workflow triggers and outputs
- Documentation and decision records

---

Now analyze the repository information below and generate the ontology:
