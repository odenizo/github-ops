#!/bin/bash
# Debug Agent Execution
# Downloads and analyzes workflow logs for troubleshooting

RUN_ID="${1:?Run ID required. Usage: $0 <RUN_ID>}"
OUTPUT_DIR="${2:-./agent-logs}"

echo "🐛 Debugging Agent Execution"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Run ID: $RUN_ID"
echo "Output: $OUTPUT_DIR"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Download run details
echo "📥 Downloading run details..."
gh run view "$RUN_ID" --json status,conclusion,jobs > "$OUTPUT_DIR/run-info.json" 2>/dev/null || {
    echo "❌ Failed to fetch run details. Run ID may be invalid."
    exit 1
}

# Download logs
echo "📥 Downloading logs..."
gh run download "$RUN_ID" -D "$OUTPUT_DIR" 2>/dev/null || echo "(some logs may not be available yet)"

# Parse and display
echo ""
echo "📄 Run Summary:"
if command -v jq &> /dev/null; then
    jq -r '.[] | "Status: \(.status)\nConclusion: \(.conclusion // "running")"' "$OUTPUT_DIR/run-info.json" 2>/dev/null || echo "(unable to parse)"
else
    cat "$OUTPUT_DIR/run-info.json"
fi

echo ""
echo "📄 Job Summary:"
if command -v jq &> /dev/null; then
    jq -r '.[] | .jobs[] | "Job: \(.name) | Status: \(.status) | Conclusion: \(.conclusion // "running")"' "$OUTPUT_DIR/run-info.json" 2>/dev/null || echo "(unable to parse)"
else
    echo "Install jq for formatted output"
fi

echo ""
echo "📡 Finding main logs..."
if find "$OUTPUT_DIR" -name "*.txt" -o -name "*.log" | head -1 | grep -q .; then
    echo "📝 Main Log Output:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    first_log=$(find "$OUTPUT_DIR" -name "*.txt" -o -name "*.log" | head -1)
    if [ -f "$first_log" ]; then
        echo "File: $first_log"
        echo ""
        head -30 "$first_log"
        echo ""
        echo "..."
        echo ""
        tail -20 "$first_log"
    fi
else
    echo "(no log files found - workflow may still be running)"
fi

echo ""
echo "✅ Logs saved to: $OUTPUT_DIR"
echo ""
echo "📡 Quick View:"
echo "  cat $OUTPUT_DIR/run-info.json"
find "$OUTPUT_DIR" -type f -name "*.txt" -o -name "*.log" | head -3 | xargs -I {} echo "  cat {}"

echo ""
echo "🔍 Troubleshooting:"
echo "  View all files: ls -la $OUTPUT_DIR"
echo "  View full logs: find $OUTPUT_DIR -name '*.txt' -o -name '*.log'"
echo "  Clear logs: rm -rf $OUTPUT_DIR"
