# Obsidian 双方向同期セットアップガイド

## 目的

MacのローカルObsidianフォルダとGoogle Driveを双方向自動同期し、Android（スマホ）でも読み書きできるようにする。

## 現在の構成

```
[Mac: /Users/akiyamaakiko/Documents/obsdian202510]
    ↓ 一方通行（30分おき自動）
[Google Drive: /obsidian-sync]
    ↓ 自動同期
[Android: Obsidian]
```

## 目標の構成

```
[Mac: /Users/akiyamaakiko/Documents/obsdian202510]
    ⇄ rclone bisync（双方向・自動）
[Google Drive: /obsidian-sync]
    ⇄ Google Driveアプリ（自動）
[Android: Obsidian]
```

---

## ⚠️ 重要な注意事項

### 既存の同期との競合について

現在、Mac → Google Driveへの一方通行の自動同期（30分おき）が動いているとのこと。
**rclone bisyncを導入する前に、この既存の同期を停止する必要があります。**

理由：
- 2つの同期ツールが同時に動くと、ファイルの競合やデータ損失のリスクがある
- rclone bisyncが双方向同期を担うので、一方通行の同期は不要になる

### バックアップの推奨

**必ず作業前にバックアップを取ってください！**

```bash
# Macのローカルフォルダをバックアップ
cp -r /Users/akiyamaakiko/Documents/obsdian202510 /Users/akiyamaakiko/Documents/obsdian202510_backup_$(date +%Y%m%d)

# Google Driveもバックアップ（別の場所にコピー）
# Google Drive Web UIで /obsidian-sync フォルダをコピー
```

---

## セットアップ手順

### ステップ 1: 既存の同期ツールを特定・停止

**まず、現在動いている自動同期が何か確認してください。**

#### A) Google Drive for Desktop を使っている場合

1. メニューバーの Google Drive アイコンをクリック
2. 設定（歯車アイコン）→ 「環境設定」
3. 現在の同期設定を確認
4. **重要**: rclone導入後は、この同期を停止するか、`/obsidian-sync` フォルダを同期対象から除外する

#### B) cronやlaunchdで自動同期している場合

以下のコマンドで確認：
```bash
# launchdのジョブを確認
launchctl list | grep -i sync
launchctl list | grep -i drive
launchctl list | grep -i obsidian

# cronジョブを確認
crontab -l
```

該当するものが見つかったら、メモしておいてください。

---

### ステップ 2: Homebrewのインストール（未インストールの場合）

ターミナルで確認：
```bash
brew --version
```

インストールされていない場合：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

### ステップ 3: Rcloneのインストール

```bash
brew install rclone
```

インストール確認：
```bash
rclone version
```

---

### ステップ 4: Rcloneの設定（Google Drive接続）

```bash
rclone config
```

以下の手順で設定：

1. `n` (New remote)
2. name: `gdrive` と入力
3. Storage: `drive` と入力（Google Driveを選択）
4. client_id: Enter（空のままでOK）
5. client_secret: Enter（空のままでOK）
6. scope: `1` (Full access)
7. root_folder_id: Enter（空のままでOK）
8. service_account_file: Enter（空のままでOK）
9. Edit advanced config? `n`
10. Use web browser to automatically authenticate? `y`
11. ブラウザが開くので、Googleアカウントでログイン・認証
12. 認証完了後、ターミナルに戻る
13. Configure this as a Shared Drive? `n`
14. `y` (Yes this is OK)
15. `q` (Quit config)

設定確認：
```bash
rclone listremotes
# gdrive: と表示されればOK
```

---

### ステップ 5: Google Driveのフォルダ構造確認

```bash
rclone lsf gdrive:
```

`obsidian-sync/` が表示されることを確認。

---

### ステップ 6: 初回同期（--resync）

**⚠️ 重要**: 初回は必ず `--resync` オプションが必要です。

**既存の同期ツールを停止してから実行してください！**

```bash
rclone bisync \
  /Users/akiyamaakiko/Documents/obsdian202510 \
  gdrive:/obsidian-sync \
  --resync \
  --verbose
```

- 数分かかる場合があります（ファイル数による）
- エラーが出た場合は、メッセージを確認

---

### ステップ 7: 手動で双方向同期をテスト

```bash
rclone bisync \
  /Users/akiyamaakiko/Documents/obsdian202510 \
  gdrive:/obsidian-sync \
  --verbose
```

**テスト方法**:
1. Macのローカルフォルダに新しいファイルを作成
2. 上記コマンドを実行
3. Google Drive Webで確認 → ファイルがアップロードされているか
4. Google Drive Webで別のファイルを作成
5. 再度上記コマンドを実行
6. Macのローカルフォルダに反映されているか確認

---

### ステップ 8: 自動同期スクリプトの作成

このプロジェクトの `scripts/obsidian-sync.sh` を使用します。

```bash
chmod +x /Users/akiyamaakiko/Documents/obsdian202510/scripts/obsidian-sync.sh
```

手動で実行してテスト：
```bash
/Users/akiyamaakiko/Documents/obsdian202510/scripts/obsidian-sync.sh
```

ログを確認：
```bash
tail -f ~/Library/Logs/obsidian-sync.log
```

---

### ステップ 9: launchdで自動化（5分おき）

このプロジェクトの `scripts/com.user.obsidian-sync.plist` を使用します。

1. **plistファイルをlaunchdディレクトリにコピー**:
   ```bash
   cp /Users/akiyamaakiko/Documents/obsdian202510/scripts/com.user.obsidian-sync.plist \
      ~/Library/LaunchAgents/
   ```

2. **launchdに登録**:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.obsidian-sync.plist
   ```

3. **即座に実行してテスト**:
   ```bash
   launchctl start com.user.obsidian-sync
   ```

4. **ログを確認**:
   ```bash
   tail -f ~/Library/Logs/obsidian-sync.log
   ```

5. **ステータス確認**:
   ```bash
   launchctl list | grep obsidian-sync
   ```

---

### ステップ 10: 既存の一方通行同期を停止

rcloneの双方向同期が正常に動作することを確認したら、既存の同期を停止してください。

#### Google Drive for Desktopの場合
- `/obsidian-sync` フォルダを同期対象から除外

#### cronやlaunchdの場合
```bash
# launchdの場合
launchctl unload ~/Library/LaunchAgents/[該当のplistファイル]

# cronの場合
crontab -e
# 該当行を削除または無効化
```

---

## トラブルシューティング

### 同期が動かない

```bash
# ログを確認
tail -50 ~/Library/Logs/obsidian-sync.log

# launchdのステータス確認
launchctl list | grep obsidian-sync

# 手動実行でエラー確認
rclone bisync /Users/akiyamaakiko/Documents/obsdian202510 gdrive:/obsidian-sync --verbose
```

### ファイルの競合が発生した場合

rclone bisyncは競合を自動で解決せず、エラーを出します。

**対処法**:
1. エラーメッセージで競合ファイルを確認
2. 手動でどちらを残すか決定
3. `--resync` で再同期

### 同期を一時停止したい

```bash
launchctl stop com.user.obsidian-sync
```

再開：
```bash
launchctl start com.user.obsidian-sync
```

---

## メンテナンス

### 同期ログの確認

```bash
tail -f ~/Library/Logs/obsidian-sync.log
```

### 同期の完全リセット

```bash
# 自動同期を停止
launchctl unload ~/Library/LaunchAgents/com.user.obsidian-sync.plist

# .rclone-bisync ディレクトリを削除
rm -rf /Users/akiyamaakiko/Documents/obsdian202510/.rclone-bisync

# 再度 --resync から実行
rclone bisync /Users/akiyamaakiko/Documents/obsdian202510 gdrive:/obsidian-sync --resync
```

---

## 参考情報

- [Rclone公式ドキュメント](https://rclone.org/)
- [Rclone bisync](https://rclone.org/bisync/)
- このプロジェクトのREADME.md

---

**質問や問題が発生した場合は、ログファイルとエラーメッセージを確認してください。**
