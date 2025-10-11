#!/bin/bash

echo "📋 n8n Logs"
echo "==========="
echo ""
echo "Showing last 100 lines of n8n logs..."
echo "(Press Ctrl+C to exit)"
echo ""

cd ~
sudo docker compose logs -f n8n --tail=100
