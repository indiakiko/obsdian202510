#!/bin/bash

# Obsidian 双方向同期スクリプト
# rclone bisyncを使用してMacローカルフォルダとGoogle Driveを同期

# 設定
LOCAL_BASE="/Users/akiyamaakiko/Documents/obsdian202510"
REMOTE_BASE="$HOME/Library/CloudStorage/GoogleDrive-indiakiko@gmail.com/マイドライブ/obsdian-sync"
LOG_FILE="$LOCAL_BASE/sync_log.txt"

# 同期対象フォルダ（既存の設定と同じ）
FOLDERS=("01_Inbox" "02_Daily" "03_Todo" "04_Templates" "20_Projects" "30_Knowledge" "ニュース")

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# エラーハンドリング
error_exit() {
    log "ERROR: $1"
    exit 1
}

# ログ開始
log "========================================"
log "同期開始: $(date)"

# rsyncがインストールされているか確認
if ! command -v rsync &> /dev/null; then
    error_exit "rsync is not installed"
fi

# ローカルパスが存在するか確認
if [ ! -d "$LOCAL_BASE" ]; then
    error_exit "Local path does not exist: $LOCAL_BASE"
fi

# リモートパスが存在するか確認
if [ ! -d "$REMOTE_BASE" ]; then
    error_exit "Remote path does not exist: $REMOTE_BASE"
fi

# 各フォルダを双方向同期
for folder in "${FOLDERS[@]}"; do
  LOCAL_FOLDER="$LOCAL_BASE/$folder"
  REMOTE_FOLDER="$REMOTE_BASE/$folder"

  if [ -d "$LOCAL_FOLDER" ]; then
    log "Transfer starting: $folder"

    # Mac → Google Drive (変更されたファイルのみ)
    rsync -av --delete \
      --exclude='.DS_Store' \
      --exclude='.obsidian/workspace*' \
      --exclude='.obsidian/cache' \
      "$LOCAL_FOLDER/" "$REMOTE_FOLDER/" >> "$LOG_FILE" 2>&1

    # Google Drive → Mac (変更されたファイルのみ)
    rsync -av \
      --exclude='.DS_Store' \
      --exclude='.obsidian/workspace*' \
      --exclude='.obsidian/cache' \
      "$REMOTE_FOLDER/" "$LOCAL_FOLDER/" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
      log "Sync completed for: $folder"
    else
      log "Sync failed for: $folder (exit code: $?)"
    fi
  else
    log "Folder not found, skipping: $folder"
  fi
done

log "同期完了: $(date)"
echo "" >> "$LOG_FILE"

exit 0
