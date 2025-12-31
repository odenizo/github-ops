#!/usr/bin/env python3
"""Sync a global instructions file into multiple target files.

Usage:
  python3 sync_global_instructions.py --source /path/to/global-instructions.md \
    --targets ~/.codex/AGENTS.md ~/.claude/CLAUDE.md ~/.gemini/GEMINI.md
"""

from __future__ import annotations

import argparse
from pathlib import Path

START = "<!-- GLOBAL-INSTRUCTIONS:START -->"
END = "<!-- GLOBAL-INSTRUCTIONS:END -->"


def upsert_block(text: str, block: str) -> str:
    if START in text and END in text:
        pre, rest = text.split(START, 1)
        _, post = rest.split(END, 1)
        return pre + START + "\n" + block + "\n" + END + post
    # append if markers missing
    sep = "\n" if text and not text.endswith("\n") else ""
    return text + sep + START + "\n" + block + "\n" + END + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--targets", nargs="+", required=True)
    args = parser.parse_args()

    source_path = Path(args.source).expanduser()
    if not source_path.exists():
        raise SystemExit(f"Source not found: {source_path}")

    block = source_path.read_text()

    for raw in args.targets:
        target = Path(raw).expanduser()
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            content = target.read_text()
        else:
            content = ""
        updated = upsert_block(content, block)
        target.write_text(updated)
        print(f"Updated: {target}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
