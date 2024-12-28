echo "Starting backup of files..."
echo "Copying files..."
cd /backup

mkdir -p ./discord/SuggestionsPlus/
cp /var/www/discord/SuggestionsPlus/data.json ./discord/SuggestionsPlus/data.json

mongodump --db test --out ./db/test

echo "Uploading backup..."
git branch -m main
git add .
git commit -m "Daily backup: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main
echo "Cleaning up..."
rm -r *
echo "Backup complete"