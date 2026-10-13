# 1Password CLI 入門指南 (摘要)

官方文件：https://developer.1password.com/docs/cli/get-started/

## 核心流程

1. 安裝 `op` CLI。
2. 在 1Password 應用程式中啟用桌面應用程式整合。
3. 解鎖應用程式。
4. 執行 `op signin` 並核准提示。
5. 使用 `op whoami` 驗證。

## 多個帳戶

- 使用 `op signin --account <subdomain.1password.com>`
- 或設定 `OP_ACCOUNT`

## 非互動式 / 自動化

- 使用服務帳戶（Service Accounts）和 `OP_SERVICE_ACCOUNT_TOKEN`
- 偏好使用 `op run` 和 `op inject` 進行運行時的秘密（secret）處理
