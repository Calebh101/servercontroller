clear
echo "Welcome to Calebh101 Server Controller Backup Script"
read -p "Press enter to start backing up, or CTRL-C to cancel. >> " user_input
echo ""
echo "Starting backup of files..."
cd /backup

mkdir -p ./discord/SuggestionsPlus/
cp /var/www/discord/SuggestionsPlus/data.json ./discord/SuggestionsPlus/data.json

mongodump --db test --out ./db/test

git branch -m main
git add .
git commit -m "Daily backup: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main
read -p "Backup complete. Press enter to cleanup. >> "
rm -r *
read -p "Backup complete. Press enter to exit. >> "