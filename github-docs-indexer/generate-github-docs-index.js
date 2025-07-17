#!/usr/bin/env node

/**
 * GitHub Docs Directory Index Generator
 * 
 * This script generates a directory index for the GitHub/docs repository
 * focusing on content and data folders for LLM-optimized file lookup.
 * 
 * Features:
 * - Uses repomix to generate comprehensive file listings
 * - Optimized for GitHub/docs repository structure
 * - Generates XML format for LLM consumption
 * - Includes search patterns and optimization hints
 * 
 * Usage: node generate-github-docs-index.js
 * 
 * Dependencies: repomix (installed via npm)
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// Configuration
const CONFIG = {
  remote: 'github/docs',
  outputFile: 'github-docs-directory-index.xml',
  tempFile: 'temp-github-docs-index.xml',
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
    '**/*.tmp',
    '**/*.lock',
    '**/coverage/**'
  ],
  repomixOptions: {
    style: 'xml',
    compress: true,
    noFileSummary: true,
    includeEmptyDirectories: false
  }
};

class GitHubDocsIndexGenerator {
  constructor() {
    this.startTime = Date.now();
    this.stats = {
      totalFiles: 0,
      contentFiles: 0,
      dataFiles: 0,
      processingTime: 0
    };
  }

  async generate() {
    console.log('🚀 Starting GitHub Docs Directory Index Generation');
    console.log(`📂 Target directories: ${CONFIG.targetDirectories.join(', ')}`);
    console.log(`📋 Include patterns: ${CONFIG.includePatterns.length} patterns`);
    console.log(`🚫 Exclude patterns: ${CONFIG.excludePatterns.length} patterns`);
    
    try {
      // Step 1: Check/Install repomix
      await this.ensureRepomix();
      
      // Step 2: Generate with repomix
      await this.generateWithRepomix();
      
      // Step 3: Process and enhance the output
      await this.processOutput();
      
      // Step 4: Create final index
      await this.createFinalIndex();
      
      // Step 5: Generate statistics
      this.generateStats();
      
      console.log('✅ GitHub Docs Directory Index generated successfully!');
      console.log(`📁 Output file: ${CONFIG.outputFile}`);
      console.log(`⏱️  Processing time: ${this.stats.processingTime}ms`);
      
    } catch (error) {
      console.error('❌ Error generating directory index:', error);
      throw error;
    }
  }

  async ensureRepomix() {
    console.log('📦 Checking repomix installation...');
    
    return new Promise((resolve, reject) => {
      exec('npx repomix --version', (error, stdout, stderr) => {
        if (error) {
          console.log('⚠️  Repomix not found, installing...');
          exec('npm install -g repomix', (installError) => {
            if (installError) {
              console.log('⚠️  Global install failed, using npx...');
              resolve();
            } else {
              console.log('✅ Repomix installed globally');
              resolve();
            }
          });
        } else {
          console.log('✅ Repomix available');
          resolve();
        }
      });
    });
  }

  async generateWithRepomix() {
    console.log('🔄 Generating directory index with repomix...');
    
    const includePattern = CONFIG.includePatterns.join(',');
    const ignorePattern = CONFIG.excludePatterns.join(',');
    
    const repomixArgs = [
      '--remote', CONFIG.remote,
      '--include', `"${includePattern}"`,
      '--ignore', `"${ignorePattern}"`,
      '--output', CONFIG.tempFile,
      '--style', CONFIG.repomixOptions.style
    ];
    
    if (CONFIG.repomixOptions.compress) {
      repomixArgs.push('--compress');
    }
    
    if (CONFIG.repomixOptions.noFileSummary) {
      repomixArgs.push('--no-file-summary');
    }
    
    if (CONFIG.repomixOptions.includeEmptyDirectories) {
      repomixArgs.push('--include-empty-directories');
    }
    
    const command = `npx repomix ${repomixArgs.join(' ')}`;
    console.log(`🔧 Running: ${command}`);
    
    return new Promise((resolve, reject) => {
      exec(command, { maxBuffer: 1024 * 1024 * 50 }, (error, stdout, stderr) => {
        if (error) {
          console.error('❌ Repomix error:', error);
          reject(error);
          return;
        }
        
        if (stderr) {
          console.log('⚠️  Repomix stderr:', stderr);
        }
        
        console.log('✅ Repomix generation completed');
        resolve();
      });
    });
  }

  async processOutput() {
    console.log('📝 Processing repomix output...');
    
    if (!fs.existsSync(CONFIG.tempFile)) {
      throw new Error(`Temporary file ${CONFIG.tempFile} not found`);
    }
    
    const content = fs.readFileSync(CONFIG.tempFile, 'utf8');
    
    // Count files and analyze content
    const fileMatches = content.match(/<file path="/g);
    this.stats.totalFiles = fileMatches ? fileMatches.length : 0;
    
    // Count content vs data files
    const contentMatches = content.match(/<file path="content\//g);
    this.stats.contentFiles = contentMatches ? contentMatches.length : 0;
    
    const dataMatches = content.match(/<file path="data\//g);
    this.stats.dataFiles = dataMatches ? dataMatches.length : 0;
    
    console.log(`📊 Processed ${this.stats.totalFiles} files`);
    console.log(`   Content files: ${this.stats.contentFiles}`);
    console.log(`   Data files: ${this.stats.dataFiles}`);
  }

  async createFinalIndex() {
    console.log('🎨 Creating final directory index...');
    
    const tempContent = fs.readFileSync(CONFIG.tempFile, 'utf8');
    
    // Extract the directory structure and files sections
    const directoryMatch = tempContent.match(/<directory_structure>(.*?)<\/directory_structure>/s);
    const filesMatch = tempContent.match(/<files>(.*?)<\/files>/s);
    
    const directoryStructure = directoryMatch ? directoryMatch[1] : '';
    const filesSection = filesMatch ? filesMatch[1] : '';
    
    const finalContent = `<?xml version="1.0" encoding="UTF-8"?>
<!-- GitHub Docs Directory Index -->
<!-- Generated for GitHub/docs repository content and data folders -->
<!-- Optimized for LLM-based file lookup and content discovery -->
<!-- Generated on: ${new Date().toISOString()} -->

<github_docs_index>
  <metadata>
    <repository>${CONFIG.remote}</repository>
    <generated_date>${new Date().toISOString()}</generated_date>
    <target_directories>
      ${CONFIG.targetDirectories.map(dir => `<directory>${dir}</directory>`).join('\n      ')}
    </target_directories>
    <include_patterns>
      ${CONFIG.includePatterns.map(pattern => `<pattern>${pattern}</pattern>`).join('\n      ')}
    </include_patterns>
    <statistics>
      <total_files>${this.stats.totalFiles}</total_files>
      <content_files>${this.stats.contentFiles}</content_files>
      <data_files>${this.stats.dataFiles}</data_files>
      <processing_time>${this.stats.processingTime}ms</processing_time>
    </statistics>
    <purpose>LLM-optimized file lookup for GitHub documentation</purpose>
  </metadata>
  
  <directory_structure>
    ${directoryStructure}
  </directory_structure>
  
  <search_patterns>
    <content_search>
      <description>Find documentation content by topic</description>
      <pattern>content/{topic}/**/*.md</pattern>
      <examples>
        <example>content/actions/**/*.md</example>
        <example>content/rest/**/*.md</example>
        <example>content/graphql/**/*.md</example>
      </examples>
    </content_search>
    <reusable_search>
      <description>Find reusable content snippets</description>
      <pattern>data/reusables/{category}/*.md</pattern>
      <examples>
        <example>data/reusables/git/*.md</example>
        <example>data/reusables/cli/*.md</example>
      </examples>
    </reusable_search>
    <configuration_search>
      <description>Find configuration and data files</description>
      <pattern>data/**/*.{yml,yaml,json,js}</pattern>
      <examples>
        <example>data/variables/*.yml</example>
        <example>data/features/*.yml</example>
      </examples>
    </configuration_search>
  </search_patterns>
  
  <optimization_hints>
    <for_llm_queries>
      <content_weight>1.0</content_weight>
      <data_weight>0.8</data_weight>
      <reusable_weight>0.6</reusable_weight>
    </for_llm_queries>
    <file_type_priorities>
      <markdown>High - Primary documentation content</markdown>
      <yaml>Medium - Configuration and structured data</yaml>
      <json>Medium - Structured data files</json>
      <javascript>Low - Data processing scripts</javascript>
    </file_type_priorities>
  </optimization_hints>
  
  <files>
    ${filesSection}
  </files>
</github_docs_index>`;
    
    fs.writeFileSync(CONFIG.outputFile, finalContent);
    
    // Clean up temp file
    if (fs.existsSync(CONFIG.tempFile)) {
      fs.unlinkSync(CONFIG.tempFile);
    }
    
    console.log(`✅ Final index created: ${CONFIG.outputFile}`);
  }

  generateStats() {
    this.stats.processingTime = Date.now() - this.startTime;
    
    if (fs.existsSync(CONFIG.outputFile)) {
      const stats = fs.statSync(CONFIG.outputFile);
      console.log(`📊 Final file size: ${(stats.size / 1024).toFixed(2)} KB`);
    }
  }
}

// CLI execution
if (require.main === module) {
  const generator = new GitHubDocsIndexGenerator();
  generator.generate().catch(error => {
    console.error('❌ Generation failed:', error);
    process.exit(1);
  });
}

module.exports = GitHubDocsIndexGenerator;