echo "Starting backup of files..."
echo "Copying files..."
cd /backup

mkdir -p ./discord/SuggestionsPlus/
cp /var/www/discord/SuggestionsPlus/data.json ./discord/SuggestionsPlus/data.json

cp -r /var/www/node/data ./node

echo "Uploading backup..."
git branch -m main
git add .
git commit -m "Daily backup: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main
echo "Cleaning up..."
sudo rm -r ./*
echo "Backup complete"