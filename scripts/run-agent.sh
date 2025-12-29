#!/bin/bash
# Run Coding Agent Workflow
# Triggers the agent-basic workflow and monitors execution

set -e

TASK="${1:-List all files in repository}"
MODEL="${2:-claude-3-5-sonnet-20241022}"

echo "🤖 Running Coding Agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task: $TASK"
echo "Model: $MODEL"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Install it: https://cli.github.com"
    exit 1
fi

# Verify authentication
if ! gh auth status &>/dev/null; then
    echo "❌ Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

# Trigger workflow
echo "📡 Triggering workflow..."
RUN_ID=$(gh workflow run agent-basic.yml \
  -F task="$TASK" \
  -F model="$MODEL" \
  --json id -q 2>/dev/null || echo "")

if [ -z "$RUN_ID" ]; then
    echo "❌ Failed to trigger workflow"
    exit 1
fi

echo "✅ Workflow triggered: $RUN_ID"
echo ""

# Poll for completion
echo "⏳ Waiting for completion (max 5 min)..."
start_time=$(date +%s)
max_wait=300  # 5 minutes

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $max_wait ]; then
        echo "⚠️  Timeout waiting for completion"
        echo "📍 Run ID: $RUN_ID"
        echo "👀 View at: https://github.com/$(gh repo view --json nameWithOwner -q)/actions/runs/$RUN_ID"
        break
    fi
    
    STATUS=$(gh run view $RUN_ID --json status -q 2>/dev/null || echo "")
    
    case $STATUS in
        "completed")
            echo "✨ Workflow completed!"
            CONCLUSION=$(gh run view $RUN_ID --json conclusion -q)
            if [ "$CONCLUSION" = "success" ]; then
                echo "🎉 SUCCESS"
                exit 0
            else
                echo "❌ FAILED"
                exit 1
            fi
            ;;
        "in_progress")
            echo -n "."
            sleep 2
            ;;
        "queued")
            echo -n "⏱"
            sleep 2
            ;;
        *)
            echo -n "?"
            sleep 2
            ;;
    esac
done
