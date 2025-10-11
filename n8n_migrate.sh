#!/bin/bash

echo "🚀 n8n Migration Script (via GitHub)"
echo "===================================="
echo ""

# Check if running on new server
read -p "Is this a NEW server where you want to restore n8n? (yes/no): " is_new_server

if [ "$is_new_server" != "yes" ]; then
    echo "❌ This script is for NEW servers only!"
    exit 1
fi

echo ""
echo "📋 Migration Mode:"
echo "1. Download backup from GitHub"
echo "2. Or upload backup to GitHub first"
echo ""

read -p "Do you have backup on GitHub already? (yes/no): " has_github_backup

if [ "$has_github_backup" = "yes" ]; then
    # Mode: Download from GitHub
    echo ""
    echo "🟢 Step 1: Installing fresh n8n..."
    curl -fsSL https://raw.githubusercontent.com/nizrem/n8n_vp/refs/heads/main/n8n_install.sh | bash
    
    if [ $? -ne 0 ]; then
        echo "❌ n8n installation failed!"
        exit 1
    fi
    
    echo "✅ n8n installed successfully!"
    echo ""
    
    # Setup ngrok
    echo "🟢 Step 2: Setting up Ngrok..."
    sh <(curl -fsSL https://raw.githubusercontent.com/nizrem/n8n_vp/refs/heads/main/n8n_ngrok.sh)
    
    if [ $? -ne 0 ]; then
        echo "❌ Ngrok setup failed!"
        exit 1
    fi
    
    echo ""
    echo "🟢 Step 3: Downloading backup from GitHub..."
    echo ""
    
    read -p "Enter GitHub username: " github_user
    read -p "Enter GitHub repo name (e.g., n8n_vp): " github_repo
    read -p "Enter backup filename: " backup_file
    read -sp "Enter GitHub Personal Access Token (PAT): " github_token
    echo ""
    
    # Create backups directory
    mkdir -p ~/n8n_backups
    
    GITHUB_URL="https://${github_user}:${github_token}@raw.githubusercontent.com/${github_user}/${github_repo}/main/${backup_file}"
    
    echo "📥 Downloading from GitHub..."
    wget -O ~/n8n_backups/$backup_file "$GITHUB_URL"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download backup from GitHub!"
        echo "❌ Check:"
        echo "   - GitHub username and repo name"
        echo "   - Personal Access Token (must have 'raw' content access)"
        echo "   - Backup file exists in GitHub repo"
        exit 1
    fi
    
    echo "✅ Backup downloaded successfully!"
    echo ""
    
else
    # Mode: Upload to GitHub first
    echo ""
    echo "🟢 Step 1: Creating backup from old data..."
    echo ""
    
    read -p "Do you have n8n_data folder locally? (yes/no): " has_local_data
    
    if [ "$has_local_data" != "yes" ]; then
        echo "❌ You need n8n_data folder to create backup!"
        echo "Copy n8n_data folder from old server first"
        exit 1
    fi
    
    # Create backup from local data
    mkdir -p ~/n8n_backups
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="n8n_backup_$TIMESTAMP.tar.gz"
    
    echo "📦 Compressing n8n data..."
    tar czf ~/n8n_backups/$BACKUP_FILE -C ~ n8n_data
    
    if [ $? -ne 0 ]; then
        echo "❌ Backup creation failed!"
        exit 1
    fi
    
    SIZE=$(du -h ~/n8n_backups/$BACKUP_FILE | cut -f1)
    echo "✅ Backup created: $BACKUP_FILE ($SIZE)"
    echo ""
    
    echo "📝 Instructions for uploading to GitHub:"
    echo ""
    echo "1. Create GitHub Personal Access Token (PAT):"
    echo "   - Go to: https://github.com/settings/tokens"
    echo "   - Click 'Generate new token (classic)'"
    echo "   - Select scopes: repo (full control)"
    echo "   - Copy the token"
    echo ""
    echo "2. Initialize git repo and push backup:"
    echo ""
    echo "   cd ~"
    echo "   git init"
    echo "   git config user.email 'you@example.com'"
    echo "   git config user.name 'Your Name'"
    echo "   git add n8n_backups/$BACKUP_FILE"
    echo "   git commit -m 'Add n8n backup'"
    echo "   git branch -M main"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/n8n_vp.git"
    echo "   git push -u origin main"
    echo ""
    echo "3. After pushing to GitHub, run this script again on NEW server"
    echo "   and select 'yes' for 'Do you have backup on GitHub already?'"
    echo ""
    
    exit 0
fi

# Restore backup
echo "🟢 Step 4: Restoring backup..."
echo ""

BACKUP_PATH="~/n8n_backups/$backup_file"
BACKUP_PATH="${BACKUP_PATH/#\~/$HOME}"

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
    echo "✅ Backup extracted successfully!"
    
    # Fix permissions
    sudo chown -R 1000:1000 ~/n8n_data
    sudo chmod -R 755 ~/n8n_data
    
    # Start n8n
    echo "🚀 Starting n8n container..."
    sudo docker compose up -d
    
    echo "⏳ Waiting for n8n to start (15 seconds)..."
    sleep 15
    
    # Verify
    echo ""
    echo "✅ Migration complete!"
    echo ""
    echo "📊 Status:"
    sh <(curl -fsSL https://raw.githubusercontent.com/nizrem/n8n_vp/refs/heads/main/n8n_status.sh)
    
else
    echo "❌ Restore failed!"
    exit 1
fi

echo ""
echo "🎉 SUCCESS! Your n8n is now migrated to this server!"
echo ""
echo "📍 Access n8n at: https://provaccine-parliamentary-nisha.ngrok-free.dev"
echo "🔐 Credentials: admin / admin"
echo ""
echo "✅ All workflows, credentials and data have been restored!"
