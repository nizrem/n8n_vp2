#!/bin/bash

echo "🔄 Restoring n8n from backup..."

BACKUP_DIR="$HOME/n8n_backups"

# List available backups
echo "📂 Available backups:"
ls -lh "$BACKUP_DIR" 2>/dev/null || {
    echo "❌ No backups found in $BACKUP_DIR"
    exit 1
}

echo ""
read -p "Enter backup filename (e.g., n8n_backup_20250101_120000.tar.gz): " BACKUP_FILE

BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

if [ ! -f "$BACKUP_PATH" ]; then
    echo "❌ Backup file not found: $BACKUP_PATH"
    exit 1
fi

# Stop n8n
echo "🛑 Stopping n8n container..."
cd ~
sudo docker compose down

# Remove current data
echo "🗑️  Removing current n8n data..."
sudo rm -rf ~/n8n_data

# Extract backup
echo "📥 Extracting backup..."
sudo tar xzf "$BACKUP_PATH" -C "$HOME"

if [ $? -eq 0 ]; then
    echo "✅ Backup restored successfully!"
    
    # Fix permissions
    sudo chown -R 1000:1000 ~/n8n_data
    sudo chmod -R 755 ~/n8n_data
    
    # Update compose.yaml with correct ngrok domain
    echo "🔧 Setting up compose.yaml with ngrok domain..."
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
    
    # Start n8n
    echo "🚀 Starting n8n container..."
    sudo docker compose up -d
    
    echo "⏳ Waiting for n8n to start..."
    sleep 15
    
    echo "✅ n8n restored and started!"
    echo "📍 Access at: https://provaccine-parliamentary-nisha.ngrok-free.dev"
    echo "🔐 OAuth Redirect URL: https://provaccine-parliamentary-nisha.ngrok-free.dev/rest/oauth2-credential/callback"
else
    echo "❌ Restore failed!"
    exit 1
fi
