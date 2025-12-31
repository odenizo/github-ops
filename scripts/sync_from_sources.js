#!/usr/bin/env node
// Simple placeholder: load config and print plan. Replace with real sync logic.
const fs = require('fs');
const path = require('path');

const cfgPath = process.argv[2] || '.github/configs/repo-sync-config.json';
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
console.log('Loaded config version', cfg.version);
for (const run of cfg.runs) {
  console.log(`Run: ${run.name} from ${run.source.repo}@${run.source.ref || 'main'}`);
  for (const item of run.items) {
    console.log(`  include: ${item.include.join(', ')} -> ${item.dest} (mode=${item.mode}) exclude=[${(item.exclude||[]).join(', ')}] strip_prefix=${item.strip_prefix||''}`);
  }
}
process.exit(0);
