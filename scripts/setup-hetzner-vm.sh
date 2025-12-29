#!/bin/bash
# Setup Hetzner VM for MCP Server Execution
# Configures a Hetzner VM with dependencies and MCP server

set -e

VM_IP="${1:?VM_IP required as first argument}"
SSH_KEY="${2:-~/.ssh/hetzner_key}"
SSH_USER="${3:-ubuntu}"

echo "🞧 Setting up Hetzner VM for GitHub HQ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VM IP: $VM_IP"
echo "SSH User: $SSH_USER"
echo "SSH Key: $SSH_KEY"
echo ""

# Verify SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH key not found: $SSH_KEY"
    exit 1
fi

# Test SSH connection
echo "🔍 Testing SSH connection..."
if ! ssh -i "$SSH_KEY" "$SSH_USER@$VM_IP" "echo OK" >/dev/null 2>&1; then
    echo "❌ SSH connection failed"
    echo "    Check: IP address, SSH key permissions, firewall rules"
    exit 1
fi
echo "✅ SSH connection OK"
echo ""

# Install dependencies on remote VM
echo "💾 Installing dependencies on VM..."
ssh -i "$SSH_KEY" "$SSH_USER@$VM_IP" << 'REMOTE_SETUP'
set -e
echo "Installing system packages..."
sudo apt update -qq
sudo apt install -y -qq curl git nodejs npm python3 python3-pip build-essential

echo "Verifying installations..."
node --version
npm --version
python3 --version

echo "\u2705 Dependencies installed successfully"
REMOTE_SETUP

echo "✅ Remote dependencies installed"
echo ""

# Create MCP server directory
echo "🖣️ Creating MCP server directory..."
ssh -i "$SSH_KEY" "$SSH_USER@$VM_IP" << 'REMOTE_MCP'
mkdir -p ~/mcp-server
cd ~/mcp-server
npm init -y > /dev/null 2>&1
npm install --save @modelcontextprotocol/sdk @anthropic-ai/sdk axios dotenv > /dev/null 2>&1
echo "\u2705 MCP directory prepared"
REMOTE_MCP

echo "✅ MCP server directory created"
echo ""

# Copy MCP server script if it exists locally
if [ -f "mcp-servers/mcp-server.js" ]; then
    echo "📋 Copying MCP server script..."
    scp -i "$SSH_KEY" mcp-servers/mcp-server.js "$SSH_USER@$VM_IP:~/mcp-server/"
    echo "✅ MCP server script copied"
else
    echo "⚠️  MCP server script not found (mcp-servers/mcp-server.js)"
    echo "    Create one locally first, then re-run this script"
fi
echo ""

# Create systemd service for MCP server
echo "📡 Setting up systemd service..."
ssh -i "$SSH_KEY" "$SSH_USER@$VM_IP" << 'REMOTE_SERVICE'
sudo tee /etc/systemd/system/mcp-server.service > /dev/null << 'EOF'
[Unit]
Description=GitHub HQ MCP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/mcp-server
ExecStart=/usr/bin/node /home/ubuntu/mcp-server/mcp-server.js
Restart=always
RestartSec=10

Environment="NODE_ENV=production"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
echo "\u2705 Systemd service configured"
REMOTE_SERVICE

echo "✅ Systemd service created"
echo ""

echo "✨ VM Setup Complete!"
echo ""
echo "📡 Next Steps:"
echo "  1. SSH to VM: ssh -i $SSH_KEY $SSH_USER@$VM_IP"
echo "  2. Start MCP: sudo systemctl start mcp-server"
echo "  3. Check logs: sudo journalctl -u mcp-server -f"
echo ""
echo "📡 To add this VM to GitHub secrets:"
echo "  gh secret set HETZNER_VM_IP --body \"$VM_IP\""
echo "  gh secret set HETZNER_SSH_KEY --body \"\$(cat $SSH_KEY)\""
echo ""
