#!/bin/bash

echo "🔧 Fixing ngrok configuration..."
echo ""

# Check if ngrok is running
if pgrep -x ngrok > /dev/null; then
    echo "⏹️  Stopping existing ngrok process..."
    pkill -9 ngrok
    sleep 2
fi

# Start ngrok with correct configuration
echo "🚀 Starting ngrok on port 5678..."
nohup ngrok http 5678 --url=https://provaccine-parliamentary-nisha.ngrok-free.dev > /tmp/ngrok.log 2>&1 &

# Wait for ngrok to initialize
sleep 5

# Verify ngrok is running
if pgrep -x ngrok > /dev/null; then
    echo "✅ Ngrok started successfully!"
    echo ""
    echo "📍 URL: https://provaccine-parliamentary-nisha.ngrok-free.dev"
    echo "🔐 OAuth Redirect URL: https://provaccine-parliamentary-nisha.ngrok-free.dev/rest/oauth2-credential/callback"
    echo ""
    echo "✅ Now you can access n8n without errors!"
else
    echo "❌ Failed to start ngrok!"
    echo "Check logs:"
    cat /tmp/ngrok.log
    exit 1
fi
