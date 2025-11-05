#!/bin/bash

# Obsidian 双方向同期スクリプト
# rclone bisyncを使用してMacローカルフォルダとGoogle Driveを同期

# 設定
LOCAL_PATH="/Users/akiyamaakiko/Documents/obsdian202510"
REMOTE_PATH="gdrive:/obsidian-sync"
LOG_FILE="$HOME/Library/Logs/obsidian-sync.log"

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
log "========== Sync Started =========="

# rcloneがインストールされているか確認
if ! command -v rclone &> /dev/null; then
    error_exit "rclone is not installed. Please install it first: brew install rclone"
fi

# ローカルパスが存在するか確認
if [ ! -d "$LOCAL_PATH" ]; then
    error_exit "Local path does not exist: $LOCAL_PATH"
fi

# bisync実行
log "Running rclone bisync..."
rclone bisync "$LOCAL_PATH" "$REMOTE_PATH" \
    --verbose \
    --log-file="$LOG_FILE" \
    --log-level INFO \
    --exclude ".DS_Store" \
    --exclude ".git/**" \
    --exclude "node_modules/**" \
    --exclude ".obsidian/workspace*" \
    2>&1 | tee -a "$LOG_FILE"

# 実行結果を確認
if [ $? -eq 0 ]; then
    log "Sync completed successfully"
else
    log "Sync failed with exit code: $?"
fi

log "========== Sync Finished =========="
echo "" >> "$LOG_FILE"

exit 0
