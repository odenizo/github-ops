# GitHub Docs Indexer

A specialized tool for generating directory indexes of the GitHub/docs repository, optimized for LLM-based file lookup and content discovery.

## Overview

This tool creates a comprehensive directory index for the GitHub/docs repository, focusing on the `content` and `data` folders. It uses [repomix](https://github.com/yamadashy/repomix) to generate a structured XML file that enables efficient file lookup for Language Learning Models (LLMs) and automated workflows.

## Features

- **LLM-Optimized**: Generates XML structure optimized for AI consumption
- **Focused Indexing**: Targets `content` and `data` directories specifically
- **Search Patterns**: Includes predefined search patterns for common queries
- **File Type Classification**: Categorizes files by type (Markdown, YAML, JSON, JavaScript)
- **Optimization Hints**: Provides weighting and priority hints for LLM queries
- **Automated Generation**: Uses repomix for comprehensive file listing
- **Statistics**: Generates file counts and processing metrics

## Structure

```
github-docs-indexer/
├── generate-github-docs-index.js    # Main generator script
├── github-docs-directory-index.xml  # Generated index file
├── package.json                     # Node.js dependencies
└── README.md                        # This file
```

## Usage

### Prerequisites

- Node.js 14+ 
- npm or yarn
- Internet connection (for remote repository access)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/odenizo/github-ops.git
cd github-ops/github-docs-indexer

# Install dependencies
npm install

# Generate the index
npm run generate
```

### Manual Installation

```bash
# Install repomix globally
npm install -g repomix

# Or install locally
npm install repomix

# Run the generator
node generate-github-docs-index.js
```

## Generated Index Structure

The generated XML file contains:

### Metadata Section
- Repository information
- Generation timestamp
- Target directories
- Include patterns
- File statistics

### Directory Structure
- Content directory tree
- Data directory tree
- File patterns per directory
- Example file paths

### File Type Categories
- **Markdown**: Documentation content and reusable snippets
- **YAML**: Configuration and structured data
- **JSON**: Structured data files
- **JavaScript**: Data processing scripts

### Search Patterns
- **Content Search**: Find documentation by topic (`content/{topic}/**/*.md`)
- **Reusable Search**: Find reusable snippets (`data/reusables/{category}/*.md`)
- **Configuration Search**: Find data files (`data/**/*.{yml,yaml,json,js}`)

### Optimization Hints
- LLM query weights
- File type priorities
- Search optimization suggestions

## Configuration

The generator can be customized by modifying the `CONFIG` object in `generate-github-docs-index.js`:

```javascript
const CONFIG = {
  remote: 'github/docs',
  outputFile: 'github-docs-directory-index.xml',
  targetDirectories: ['content', 'data'],
  includePatterns: [
    'content/**/*.md',
    'data/**/*.yml',
    'data/**/*.yaml',
    'data/**/*.json',
    'data/**/*.js',
    'data/**/*.md'
  ],
  excludePatterns: [
    '**/node_modules/**',
    '**/.git/**',
    '**/build/**',
    '**/dist/**',
    '**/*.log',
    '**/*.tmp'
  ],
  repomixOptions: {
    style: 'xml',
    compress: true,
    noFileSummary: true,
    includeEmptyDirectories: false
  }
};
```

## Example Queries

### Find Actions Documentation
```
content/actions/**/*.md
```

### Find Git Reusables
```
data/reusables/git/*.md
```

### Find Product Variables
```
data/variables/product.yml
```

## Integration with LLMs

The generated index is optimized for LLM consumption:

1. **Structured XML**: Easy to parse and understand
2. **Search Patterns**: Predefined query patterns for common use cases
3. **Optimization Hints**: Weights and priorities for better relevance
4. **File Classification**: Clear categorization of content types

### Example LLM Query
```
"Using the GitHub docs directory index, find all files related to GitHub Actions authentication"
```

The LLM can use the search patterns to query:
- `content/actions/**/*.md` for documentation
- `data/reusables/actions/*.md` for reusable content
- `data/variables/actions.yml` for configuration

## Scripts

- `npm run generate`: Generate the directory index
- `npm run start`: Same as generate
- `npm run update`: Update the existing index
- `npm run install-deps`: Install repomix dependency
- `npm test`: Basic functionality test

## Dependencies

- [repomix](https://github.com/yamadashy/repomix): Repository packing tool
- Node.js built-in modules: `fs`, `path`, `child_process`

## Output Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<github_docs_index>
  <metadata>
    <repository>github/docs</repository>
    <generated_date>2025-01-17T20:00:00.000Z</generated_date>
    <target_directories>
      <directory>content</directory>
      <directory>data</directory>
    </target_directories>
    <statistics>
      <total_files>1250</total_files>
      <content_files>800</content_files>
      <data_files>450</data_files>
    </statistics>
  </metadata>
  
  <directory_structure>
    <!-- Directory tree structure -->
  </directory_structure>
  
  <search_patterns>
    <!-- Query patterns for LLM optimization -->
  </search_patterns>
  
  <files>
    <!-- Complete file listing -->
  </files>
</github_docs_index>
```

## Automation

This tool can be integrated into CI/CD pipelines:

1. **GitHub Actions**: Automatically update the index on repository changes
2. **Scheduled Updates**: Run periodically to keep the index current
3. **Integration**: Use the index in LLM workflows and documentation tools

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the generator
5. Submit a pull request

## License

MIT License - see the main repository for details.

## Support

For issues and questions:
- Open an issue in the [github-ops repository](https://github.com/odenizo/github-ops/issues)
- Check the [repomix documentation](https://github.com/yamadashy/repomix) for underlying tool issues

## Related Projects

- [repomix](https://github.com/yamadashy/repomix): Repository packing tool
- [github/docs](https://github.com/github/docs): GitHub documentation source
- [odenizo/github-ops](https://github.com/odenizo/github-ops): GitHub operations automation center