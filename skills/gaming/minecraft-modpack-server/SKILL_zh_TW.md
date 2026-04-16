---
name: minecraft-modpack-server
description: 從 CurseForge/Modrinth 伺服器包 zip 檔架設模組化 Minecraft 伺服器。涵蓋 NeoForge/Forge 安裝、Java 版本、JVM 調優、防火牆、LAN 設定、備份及啟動指令碼。
tags: [minecraft, gaming, server, neoforge, forge, modpack]
---

# Minecraft 模組包 (Modpack) 伺服器架設

## 何時使用
- 使用者想要從伺服器包 zip 檔架設模組化 Minecraft 伺服器
- 使用者需要 NeoForge/Forge 伺服器設定方面的協助
- 使用者詢問關於 Minecraft 伺服器效能調優或備份的問題

## 首先收集使用者偏好
在開始設定之前，請詢問使用者：
- **伺服器名稱 / MOTD** —— 在伺服器清單中應該顯示什麼？
- **種子碼 (Seed)** —— 指定種子碼還是隨機？
- **難度 (Difficulty)** —— 和平 (peaceful) / 簡單 (easy) / 普通 (normal) / 困難 (hard)？
- **遊戲模式 (Gamemode)** —— 生存 (survival) / 創造 (creative) / 冒險 (adventure)？
- **線上模式 (Online mode)** —— true (Mojang 驗證，正版帳號) 或 false (LAN/區域網路/盜版友善)？
- **玩家人數** —— 預計有多少玩家？ (影響 RAM 與視距調優)
- **RAM 分配** —— 或者讓 Agent 根據模組數量與可用 RAM 決定？
- **視距 (View distance) / 模擬距離 (Simulation distance)** —— 或者讓 Agent 根據玩家人數與硬體決定？
- **PvP** —— 開啟或關閉？
- **白名單 (Whitelist)** —— 公開伺服器還是僅限白名單？
- **備份** —— 是否需要自動備份？頻率為何？

如果使用者不在意，請使用合理的預設值，但在產生設定檔之前務必先詢問。

## 步驟

### 1. 下載並檢查該包 (Pack)
```bash
mkdir -p ~/minecraft-server
cd ~/minecraft-server
wget -O serverpack.zip "<URL>"
unzip -o serverpack.zip -d server
ls server/
```
尋找：`startserver.sh`、安裝程式 jar (neoforge/forge)、`user_jvm_args.txt`、`mods/` 資料夾。
檢查指令碼以確定：模組載入器類型、版本以及所需的 Java 版本。

### 2. 安裝 Java
- Minecraft 1.21+ → Java 21: `sudo apt install openjdk-21-jre-headless`
- Minecraft 1.18-1.20 → Java 17: `sudo apt install openjdk-17-jre-headless`
- Minecraft 1.16 及以下版本 → Java 8: `sudo apt install openjdk-8-jre-headless`
- 驗證：`java -version`

### 3. 安裝模組載入器 (Mod Loader)
大多數伺服器包都包含安裝指令碼。使用 INSTALL_ONLY 環境變數來安裝而不啟動：
```bash
cd ~/minecraft-server/server
ATM10_INSTALL_ONLY=true bash startserver.sh
# 或者對於一般的 Forge 包：
# java -jar forge-*-installer.jar --installServer
```
這會下載函式庫、修補伺服器 jar 等。

### 4. 接受 EULA
```bash
echo "eula=true" > ~/minecraft-server/server/eula.txt
```

### 5. 設定 server.properties
模組化/LAN 的關鍵設定：
```properties
motd=\u00a7b\u00a7lServer Name \u00a7r\u00a78| \u00a7aModpack Name
server-port=25565
online-mode=true          # false 用於不透過 Mojang 驗證的 LAN
enforce-secure-profile=true  # 與 online-mode 相符
difficulty=hard            # 大多數模組包平衡性基於困難模式
allow-flight=true          # 模組化伺服器「必備」 (飛行坐騎/物品)
spawn-protection=0         # 讓每個人都能在出生點建築
max-tick-time=180000       # 模組化需要更長的 tick 逾時
enable-command-block=true
```

效能設定 (視硬體調整)：
```properties
# 2 名玩家，強大機器：
view-distance=16
simulation-distance=10

# 4-6 名玩家，中等機器：
view-distance=10
simulation-distance=6

# 8 名以上玩家或硬體較弱：
view-distance=8
simulation-distance=4
```

### 6. 調優 JVM 參數 (user_jvm_args.txt)
根據玩家人數與模組數量調整 RAM。模組化的經驗法則：
- 100-200 個模組：6-12GB
- 200-350 個以上模組：12-24GB
- 至少預留 8GB 給作業系統/其他工作

```
-Xms12G
-Xmx24G
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:MaxGCPauseMillis=200
-XX:+UnlockExperimentalVMOptions
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-XX:G1NewSizePercent=30
-XX:G1MaxNewSizePercent=40
-XX:G1HeapRegionSize=8M
-XX:G1ReservePercent=20
-XX:G1HeapWastePercent=5
-XX:G1MixedGCCountTarget=4
-XX:InitiatingHeapOccupancyPercent=15
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32
-XX:+PerfDisableSharedMem
-XX:MaxTenuringThreshold=1
```

### 7. 開啟防火牆
```bash
sudo ufw allow 25565/tcp comment "Minecraft Server"
```
檢查：`sudo ufw status | grep 25565`

### 8. 建立啟動指令碼
```bash
cat > ~/start-minecraft.sh << 'EOF'
#!/bin/bash
cd ~/minecraft-server/server
java @user_jvm_args.txt @libraries/net/neoforged/neoforge/<VERSION>/unix_args.txt nogui
EOF
chmod +x ~/start-minecraft.sh
```
注意：對於 Forge (非 NeoForge)，參數檔案路徑不同。請檢查 `startserver.sh` 以獲取確切路徑。

### 9. 設定自動備份
建立備份指令碼：
```bash
cat > ~/minecraft-server/backup.sh << 'SCRIPT'
#!/bin/bash
SERVER_DIR="$HOME/minecraft-server/server"
BACKUP_DIR="$HOME/minecraft-server/backups"
WORLD_DIR="$SERVER_DIR/world"
MAX_BACKUPS=24
mkdir -p "$BACKUP_DIR"
[ ! -d "$WORLD_DIR" ] && echo "[BACKUP] No world folder" && exit 0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/world_${TIMESTAMP}.tar.gz"
echo "[BACKUP] Starting at $(date)"
tar -czf "$BACKUP_FILE" -C "$SERVER_DIR" world
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[BACKUP] Saved: $BACKUP_FILE ($SIZE)"
BACKUP_COUNT=$(ls -1t "$BACKUP_DIR"/world_*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    REMOVE=$((BACKUP_COUNT - MAX_BACKUPS))
    ls -1t "$BACKUP_DIR"/world_*.tar.gz | tail -n "$REMOVE" | xargs rm -f
    echo "[BACKUP] Pruned $REMOVE old backup(s)"
fi
echo "[BACKUP] Done at $(date)"
SCRIPT
chmod +x ~/minecraft-server/backup.sh
```

加入每小時 cron 排程：
```bash
(crontab -l 2>/dev/null | grep -v "minecraft/backup.sh"; echo "0 * * * * $HOME/minecraft-server/backup.sh >> $HOME/minecraft-server/backups/backup.log 2>&1") | crontab -
```

## 常見陷阱
- 模組化伺服器「務必」設定 `allow-flight=true` —— 否則有噴射背包/飛行功能的模組會踢掉玩家
- `max-tick-time=180000` 或更高 —— 模組化伺服器在生成世界時常有較長的 tick
- 第一次啟動很慢 (大型包需要幾分鐘) —— 請勿驚慌
- 第一次啟動時出現 "Can't keep up!" 警告是正常的，在初始區塊生成後會趨於穩定
- 如果 online-mode=false，則 enforce-secure-profile 也要設為 false，否則用戶端會被拒絕
- 該包的 startserver.sh 通常有一個自動重新啟動迴圈 —— 請建立一個不含該迴圈的乾淨啟動指令碼
- 刪除 world/ 資料夾以使用新種子重新生成
- 某些包使用環境變數控制行為 (例如：ATM10 使用 ATM10_JAVA, ATM10_RESTART, ATM10_INSTALL_ONLY)

## 驗證
- `pgrep -fa neoforge` 或 `pgrep -fa minecraft` 檢查是否正在執行
- 檢查記錄：`tail -f ~/minecraft-server/server/logs/latest.log`
- 在記錄中尋找 "Done (Xs)!" = 伺服器已就緒
- 測試連線：玩家在多人遊戲中加入伺服器 IP
