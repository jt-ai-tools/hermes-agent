#!/bin/bash
# 檢查翻譯完整度
# 規則：對於每一個 .md(x) 檔案，應該都要有一個對應的 _zh_TW.md(x) 檔案

ALL_FILES=$(./scripts/list_md_files.sh)
TOTAL=$(echo "$ALL_FILES" | wc -l)
MISSING=0

echo "開始檢查翻譯狀態..."
for file in $ALL_FILES; do
    # 取得副檔名
    ext="${file##*.}"
    # 取得檔名 (不含副檔名)
    base="${file%.*}"
    zh_file="${base}_zh_TW.${ext}"
    
    if [ ! -f "$zh_file" ]; then
        echo "缺少翻譯: $file -> 預期 $zh_file"
        MISSING=$((MISSING + 1))
    fi
done

echo "-----------------------------------"
echo "總計需要翻譯檔案: $TOTAL"
echo "目前缺少翻譯檔案: $MISSING"
DONE=$((TOTAL - MISSING))
PERCENT=$(awk "BEGIN {print ($DONE/$TOTAL)*100}")
printf "目前完成進度: %d/%d (%.2f%%)\n" "$DONE" "$TOTAL" "$PERCENT"
