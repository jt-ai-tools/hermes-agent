---
name: obsidian
description: 在 Obsidian 保險箱 (vault) 中閱讀、搜尋和建立筆記。
---

# Obsidian 保險箱 (Vault)

**位置：** 透過 `OBSIDIAN_VAULT_PATH` 環境變數設定（例如在 `~/.hermes/.env` 中）。

如果未設定，預設為 `~/Documents/Obsidian Vault`。

注意：保險箱路徑可能包含空格 - 請務必使用引號括起來。

## 閱讀筆記

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
cat "$VAULT/Note Name.md"
```

## 列出筆記

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"

# 所有筆記
find "$VAULT" -name "*.md" -type f

# 在特定資料夾中
ls "$VAULT/Subfolder/"
```

## 搜尋

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"

# 依檔名搜尋
find "$VAULT" -name "*.md" -iname "*keyword*"

# 依內容搜尋
grep -rli "keyword" "$VAULT" --include="*.md"
```

## 建立筆記

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
cat > "$VAULT/New Note.md" << 'ENDNOTE'
# 標題

在此輸入內容。
ENDNOTE
```

## 附加到筆記

```bash
VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}"
echo "
在此輸入新內容。" >> "$VAULT/Existing Note.md"
```

## 雙鏈 (Wikilinks)

Obsidian 使用 `[[Note Name]]` 語法連結筆記。建立筆記時，請使用此語法連結相關內容。
