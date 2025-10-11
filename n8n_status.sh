#!/bin/bash

echo "📊 n8n Status Report"
echo "==================="
echo ""

# Check Docker container status
echo "🐳 Docker Container Status:"
sudo docker ps --filter "name=n8n_container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# Check if container is running
if sudo docker ps --filter "name=n8n_container" -q | grep -q .; then
    echo "✅ n8n container is RUNNING"
    
    # Get container ID
    CONTAINER_ID=$(sudo docker ps --filter "name=n8n_container" -q)
    
    # Check n8n version
    N8N_VERSION=$(sudo docker exec "$CONTAINER_ID" n8n --version 2>/dev/null || echo "unknown")
    echo "📦 n8n Version: $N8N_VERSION"
    
    # Check ffmpeg
    if sudo docker exec "$CONTAINER_ID" ffmpeg -version > /dev/null 2>&1; then
        echo "🎬 ffmpeg: ✅ Installed"
    else
        echo "🎬 ffmpeg: ❌ Not found"
    fi
    
    # Check disk usage
    echo ""
    echo "💾 Disk Usage:"
    du -sh ~/n8n_data 2>/dev/null || echo "Cannot read n8n_data"
    
    # Check ngrok status
    echo ""
    echo "🌐 Ngrok Status:"
    if pgrep -x ngrok > /dev/null; then
        echo "✅ Ngrok is RUNNING"
        echo "📍 URL: https://provaccine-parliamentary-nisha.ngrok-free.dev"
    else
        echo "❌ Ngrok is NOT running"
        echo "⚠️  Start ngrok with:"
        echo "   sh <(curl -fsSL https://raw.githubusercontent.com/nizrem/n8n_vp/refs/heads/main/n8n_ngrok.sh)"
    fi
    
else
    echo "❌ n8n container is NOT running"
    echo ""
    echo "🚀 To start n8n:"
    echo "   cd ~"
    echo "   sudo docker compose up -d"
fi

echo ""
echo "📍 Access n8n at: https://provaccine-parliamentary-nisha.ngrok-free.dev"
echo "🔐 Credentials: admin / admin"
