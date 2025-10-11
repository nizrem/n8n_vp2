#!/bin/bash

echo "💾 Creating manual backup of n8n data..."

BACKUP_DIR="$HOME/n8n_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/n8n_backup_$TIMESTAMP.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup n8n data
echo "📦 Compressing n8n data..."
sudo tar czf "$BACKUP_FILE" -C "$HOME" n8n_data

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ Backup created successfully!"
    echo "📍 Location: $BACKUP_FILE"
    echo "📊 Size: $SIZE"
    echo ""
    echo "ℹ️  Latest backups:"
    ls -lh "$BACKUP_DIR" | tail -5
else
    echo "❌ Backup failed!"
    exit 1
fi
