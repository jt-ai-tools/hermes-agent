#!/bin/bash
# 列出所有需要翻譯的 Markdown 檔案 (排除已翻譯、PROGRESS.md 及隱藏資料夾)
find . -type f \( -name "*.md" -o -name "*.mdx" \) \
    ! -name "*_zh_TW.md" \
    ! -name "*_zh_TW.mdx" \
    ! -name "PROGRESS.md" \
    ! -path "*/.*" \
    ! -path "./venv/*" \
    ! -path "./node_modules/*"
