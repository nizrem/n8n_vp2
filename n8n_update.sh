#!/bin/bash

echo "🔄 Starting n8n update process..."

# Check if compose.yaml exists
if [ ! -f ~/compose.yaml ]; then
    echo "❌ Error: compose.yaml not found in home directory!"
    exit 1
fi

cd ~

# Backup old data
echo "💾 Creating backup..."
if [ -d ~/n8n_data_backup ]; then
    echo "🗑️  Removing old backup..."
    sudo rm -rf ~/n8n_data_backup
fi

echo "📦 Backing up n8n data..."
sudo cp -r ~/n8n_data ~/n8n_data_backup
echo "✅ Backup created at ~/n8n_data_backup"

# Stop containers
echo "🛑 Stopping n8n container..."
sudo docker compose down

# Pull latest n8n image
echo "📥 Pulling latest n8n image..."
sudo docker pull n8nio/n8n:latest

# Rebuild image with latest n8n and ffmpeg
echo "🔨 Rebuilding custom image with latest n8n and ffmpeg..."
sudo docker compose build --no-cache

# Ensure compose.yaml has correct environment variables
echo "🔧 Updating compose.yaml with ngrok domain..."
NGROK_DOMAIN="provaccine-parliamentary-nisha.ngrok-free.dev"

# Update or create compose.yaml with correct settings
cat > ~/compose.yaml << 'EOF'
version: "3.9"
services:
  n8n:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    container_name: n8n_container
    environment:
      - GENERIC_TIMEZONE=Europe/Tallinn
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin
      - WEBHOOK_URL=https://provaccine-parliamentary-nisha.ngrok-free.dev/
      - N8N_EDITOR_BASE_URL=https://provaccine-parliamentary-nisha.ngrok-free.dev/
      - WEBHOOK_TUNNEL_URL=https://provaccine-parliamentary-nisha.ngrok-free.dev/
      - N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
      - N8N_SECURE_COOKIE=false
      - N8N_DEFAULT_BINARY_DATA_MODE=filesystem
    ports:
      - "5678:5678"
    volumes:
      - ~/n8n_data:/home/node/.n8n
EOF

echo "✅ compose.yaml updated with ngrok domain"

# Start containers
echo "🚀 Starting n8n container..."
sudo docker compose up -d

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 10

# Get n8n version
N8N_VERSION=$(sudo docker exec n8n_container n8n --version 2>/dev/null || echo "unknown")
echo "✅ n8n version: $N8N_VERSION"

# Wait for container to fully start
echo "⏳ Waiting for n8n to fully initialize (20 seconds)..."
sleep 20

# Check ngrok status
echo ""
echo "🔍 Checking ngrok status..."
if pgrep -x ngrok > /dev/null; then
    echo "✅ Ngrok is running"
    
    # Verify ngrok is on correct port
    echo "🔧 Verifying ngrok configuration..."
    NGROK_LOG=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o "http://localhost:[0-9]*" || echo "")
    
    if [ -z "$NGROK_LOG" ]; then
        echo "⚠️  Ngrok may not be on correct port (5678)"
        echo "Restarting ngrok..."
        pkill -9 ngrok
        sleep 2
        nohup ngrok http 5678 --url=https://provaccine-parliamentary-nisha.ngrok-free.dev > /tmp/ngrok.log 2>&1 &
        sleep 5
        echo "✅ Ngrok restarted"
    fi
else
    echo "❌ Ngrok is NOT running!"
    echo "🚀 Starting ngrok..."
    nohup ngrok http 5678 --url=https://provaccine-parliamentary-nisha.ngrok-free.dev > /tmp/ngrok.log 2>&1 &
    sleep 5
    echo "✅ Ngrok started"
fi

echo ""
echo "🎉 Update complete!"
echo "📍 Access n8n at: https://provaccine-parliamentary-nisha.ngrok-free.dev"
echo "🔐 OAuth URL: https://provaccine-parliamentary-nisha.ngrok-free.dev/rest/oauth2-credential/callback"
echo "💾 Backup location: ~/n8n_data_backup"
echo ""
echo "ℹ️  To restore from backup if needed:"
echo "   sudo docker compose down"
echo "   sudo rm -rf ~/n8n_data"
echo "   sudo cp -r ~/n8n_data_backup ~/n8n_data"
echo "   sudo docker compose up -d"
