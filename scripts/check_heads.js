#!/usr/bin/env node
// Check upstream HEADs for repos in repo-sync config.
// Emits JSON to stdout and updates .cache/repo-heads.json

const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

const cfgPath = process.argv[2] || '.github/configs/repo-sync-config.json';
const cachePath = path.join('.cache', 'repo-heads.json');

const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const prev = fs.existsSync(cachePath) ? JSON.parse(fs.readFileSync(cachePath, 'utf8')) : {};

function getHead(repo, ref = 'main') {
  const out = execSync(`git ls-remote https://github.com/${repo}.git ${ref}`, { encoding: 'utf8' });
  const sha = out.split('\t')[0].trim();
  return sha || null;
}

const results = {};
let changed = false;

for (const run of cfg.runs) {
  const repo = run.source.repo;
  const ref = run.source.ref || 'main';
  const key = `${repo}@${ref}`;
  const sha = getHead(repo, ref);
  results[key] = sha;
  if (!prev[key] || prev[key] !== sha) {
    changed = true;
  }
}

fs.mkdirSync(path.dirname(cachePath), { recursive: true });
fs.writeFileSync(cachePath, JSON.stringify(results, null, 2));

console.log(JSON.stringify({ changed, heads: results }, null, 2));
