#!/bin/bash
echo "Starting backup utility..."

dir=/backup
date=$(date '+%Y-%m-%d %H:%M:%S')

cd /backup
echo "Starting backup of files..."

echo "Copying data..."
mkdir -p "./data/node" && cp -r "/var/www/node/data" "$_"
mkdir -p "./data/discord/SuggestionsPlus" && cp "/var/www/discord/SuggestionsPlus/data.json" "$_/data.json"

echo "Dumping databases..."
mongodump --out ./db

echo "Creating ZIP file..."
zip -r backup.zip .

echo "Backup complete"
echo "Results: $(ls --color=auto -m)"