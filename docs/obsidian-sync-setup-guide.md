# Obsidian 双方向同期セットアップガイド

## 目的

MacのローカルObsidianフォルダとGoogle Driveを双方向自動同期し、Android（スマホ）でも読み書きできるようにする。

## 現在の構成

```
[Mac: /Users/akiyamaakiko/Documents/obsdian202510]
    ↓ 一方通行（30分おき・rsync）
[Google Drive: ~/Library/CloudStorage/.../obsdian-sync]
    ↓ 自動同期
[Android: Obsidian]
```

**問題点**: Mac → Google Driveの一方通行なので、スマホで編集してもMacに反映されない

## 目標の構成

```
[Mac: /Users/akiyamaakiko/Documents/obsdian202510]
    ⇄ rsync 双方向（30分おき・自動）
[Google Drive: ~/Library/CloudStorage/.../obsdian-sync]
    ⇄ Google Driveアプリ（自動）
[Android: Obsidian]
```

**改善**: 双方向同期なので、Mac/スマホどちらで編集しても相互に反映される

---

## ⚠️ 重要な注意事項

### バックアップの推奨

**必ず作業前にバックアップを取ってください！**

```bash
# Macのローカルフォルダをバックアップ
cp -r /Users/akiyamaakiko/Documents/obsdian202510 /Users/akiyamaakiko/Documents/obsdian202510_backup_$(date +%Y%m%d)

# Google Driveもバックアップ（Web UIで別フォルダにコピー）
```

---

## セットアップ手順

### ステップ 1: 既存の同期ジョブを停止

現在 `com.obsidian.sync` が動いています。これを停止します。

```bash
# 既存のジョブを停止＆解除
launchctl stop com.obsidian.sync
launchctl unload ~/Library/LaunchAgents/com.obsidian.sync.plist
```

確認：
```bash
launchctl list | grep obsidian
# 何も表示されなければOK
```

---

### ステップ 2: 新しい双方向同期スクリプトを配置

このプロジェクトに含まれる新しいスクリプトを使います。

```bash
# 実行権限を付与
chmod +x /Users/akiyamaakiko/Documents/obsdian202510/scripts/obsidian-sync.sh
```

---

### ステップ 3: 手動で双方向同期をテスト

**重要**: まず手動で実行して、正常に動作するか確認します。

```bash
# スクリプトを手動実行
/Users/akiyamaakiko/Documents/obsdian202510/scripts/obsidian-sync.sh
```

**テスト方法**:

1. **Mac → Google Drive の確認**
   - Macのローカルフォルダに新しいファイルを作成（例: `30_Knowledge/test.md`）
   - スクリプトを実行
   - Google Drive Web UIで確認 → ファイルがアップロードされているか

2. **Google Drive → Mac の確認**
   - Google Drive Web UIで別のファイルを作成（例: `30_Knowledge/test2.md`）
   - スクリプトを実行
   - Macのローカルフォルダに反映されているか確認

3. **ログの確認**
   ```bash
   cat /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt
   ```

正常に動作していれば、次のステップへ。

---

### ステップ 4: 新しい自動同期ジョブを登録

```bash
# plistファイルをLaunchAgentsディレクトリにコピー
cp /Users/akiyamaakiko/Documents/obsdian202510/scripts/com.user.obsidian-sync.plist \
   ~/Library/LaunchAgents/com.user.obsidian-bisync.plist

# launchdに登録
launchctl load ~/Library/LaunchAgents/com.user.obsidian-bisync.plist
```

確認：
```bash
launchctl list | grep obsidian
# com.user.obsidian-bisync が表示されればOK
```

---

### ステップ 5: 自動同期の動作確認

```bash
# 即座に実行してテスト
launchctl start com.user.obsidian-bisync

# ログを確認
tail -f /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt
```

30分後に自動実行されるので、しばらく待ってログを確認してください。

---

### ステップ 6: 既存のplistファイルを削除（任意）

新しい同期が正常に動作することを確認したら、古いplistファイルを削除できます。

```bash
# バックアップを取ってから削除
mv ~/Library/LaunchAgents/com.obsidian.sync.plist ~/Library/LaunchAgents/com.obsidian.sync.plist.bak
```

---

## 同期の仕組み

### 対象フォルダ

以下の7つのフォルダが同期されます：
- `01_Inbox`
- `02_Daily`
- `03_Todo`
- `04_Templates`
- `20_Projects`
- `30_Knowledge` ← **読書ノート（20_Books）もここに含まれる**
- `ニュース`

### 除外設定

以下のファイルは同期から除外されます：
- `.DS_Store`
- `.obsidian/workspace*`
- `.obsidian/cache`

### 双方向同期の流れ

スクリプトは以下の順序で実行されます：

1. **Mac → Google Drive**:
   - Macで変更されたファイルをGoogle Driveにアップロード
   - `--delete` オプションで、Mac側で削除されたファイルはGoogle Driveからも削除

2. **Google Drive → Mac**:
   - Google Driveで変更されたファイルをMacにダウンロード
   - 削除されたファイルはそのまま（`--delete` なし）

### 競合の扱い

- rsyncは「新しいファイル」を優先します
- 同時に両方で編集すると、後に実行された方が残ります
- **推奨**: 同時編集を避ける（Mac or スマホのどちらか一方で編集）

---

## トラブルシューティング

### 同期が動かない

```bash
# ログを確認
tail -50 /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt

# launchdのステータス確認
launchctl list | grep obsidian

# 手動実行でエラー確認
/Users/akiyamaakiko/Documents/obsdian202510/scripts/obsidian-sync.sh
```

### Google Driveのパスが見つからない

Google Drive for Desktopがインストールされていることを確認：
```bash
ls ~/Library/CloudStorage/
# GoogleDrive-indiakiko@gmail.com が存在するか確認
```

### 同期を一時停止したい

```bash
launchctl stop com.user.obsidian-bisync
```

再開：
```bash
launchctl start com.user.obsidian-bisync
```

完全に無効化：
```bash
launchctl unload ~/Library/LaunchAgents/com.user.obsidian-bisync.plist
```

再度有効化：
```bash
launchctl load ~/Library/LaunchAgents/com.user.obsidian-bisync.plist
```

---

## スマホ（Android）側の設定

Androidのスマホでは、Obsidianアプリが既にGoogle Driveの `/obsdian-sync` フォルダを参照しているはずです。

確認事項：
1. Obsidianアプリで正しいVaultが開いているか
2. Google Driveアプリで同期が有効になっているか
3. 十分なストレージ容量があるか

---

## メンテナンス

### 同期ログの確認

```bash
# リアルタイムでログを表示
tail -f /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt

# 最新50行を表示
tail -50 /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt
```

### ログファイルのクリーンアップ

ログが大きくなりすぎた場合：
```bash
# ログを保存してクリア
mv /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt \
   /Users/akiyamaakiko/Documents/obsdian202510/sync_log_$(date +%Y%m%d).txt
touch /Users/akiyamaakiko/Documents/obsdian202510/sync_log.txt
```

---

## よくある質問

### Q: 30分おきだと遅い。もっと頻繁に同期したい

plistファイルの `StartInterval` を変更してください：

```bash
# plistを編集
nano ~/Library/LaunchAgents/com.user.obsidian-bisync.plist

# <integer>1800</integer> を変更
# 例: 5分おき → <integer>300</integer>

# 再読み込み
launchctl unload ~/Library/LaunchAgents/com.user.obsidian-bisync.plist
launchctl load ~/Library/LaunchAgents/com.user.obsidian-bisync.plist
```

### Q: 読書ノートだけ同期したい

スクリプトの `FOLDERS` 配列を編集：

```bash
nano /Users/akiyamaakiko/Documents/obsdian202510/scripts/obsidian-sync.sh

# FOLDERS=("30_Knowledge") だけにする
```

### Q: rclone bisyncに変更したい

rclone bisyncの方が高度な双方向同期が可能です。興味があれば別途設定できます。

---

## 参考情報

- このプロジェクトのREADME.md
- [rsync公式マニュアル](https://download.samba.org/pub/rsync/rsync.html)

---

**質問や問題が発生した場合は、ログファイルとエラーメッセージを確認してください。**
