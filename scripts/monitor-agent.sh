#!/bin/bash
# Monitor Agent Execution in Real-Time
# Continuously displays workflow execution status and logs

REFRESH_RATE="${1:-5}"  # Refresh interval in seconds

echo "👀 GitHub HQ Agent Monitor"
echo "Refresh rate: ${REFRESH_RATE}s (Ctrl+C to exit)"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found"
    exit 1
fi

while true; do
    clear
    echo "👀 GitHub HQ Agent Monitor - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Get recent runs
    echo "📄 Recent Workflow Runs:"
    gh run list --limit 10 --json status,name,updatedAt,conclusion -q | \
        jq -r '.[] | "\(.status | ascii_downcase | if . == "completed" then "✅" elif . == "in_progress" then "🔄" else "⏳" end) \(.name) - \(.conclusion // "running") - \(.updatedAt[:10])"' || echo "   (failed to fetch runs)"
    
    echo ""
    
    # Get latest run details
    LATEST=$(gh run list --limit 1 --json databaseId -q 2>/dev/null | jq -r '.[0].databaseId // empty')
    if [ -n "$LATEST" ]; then
        echo "🔍 Latest Run Details:"
        gh run view "$LATEST" --json status,conclusion,startedAt,updatedAt -q | \
            jq -r '.[] | "  Status: \(.status)\nConclusion: \(.conclusion // "running")\nStarted: \(.startedAt)\nUpdated: \(.updatedAt)"' 2>/dev/null || echo "   (failed to fetch details)"
    fi
    
    echo ""
    echo "⏳ Next refresh in ${REFRESH_RATE}s (press Ctrl+C to exit)..."
    sleep "$REFRESH_RATE"
done
