# 身分驗證與設定

## 安裝 CLI

```bash
curl -fsSL https://cli.inference.sh | sh
```

## 登入

```bash
infsh login
```

這將開啟瀏覽器進行身分驗證。登入後，憑證將儲存在本地。

## 檢查身分驗證狀態

```bash
infsh me
```

若已驗證，將顯示您的使用者資訊。

## 環境變數

若用於 CI/CD 或腳本，請設定您的 API 金鑰：

```bash
export INFSH_API_KEY=your-api-key
```

環境變數的優先級高於設定檔。

## 更新 CLI

```bash
infsh update
```

或重新安裝：

```bash
curl -fsSL https://cli.inference.sh | sh
```

## 疑難排解

| 錯誤 | 解決方案 |
|-------|----------|
| "not authenticated" (未驗證) | 執行 `infsh login` |
| "command not found" (找不到命令) | 重新安裝 CLI 或將其加入 PATH |
| "API key invalid" (API 金鑰無效) | 檢查 `INFSH_API_KEY` 或重新登入 |

## 相關文件

- [CLI Setup](https://inference.sh/docs/extend/cli-setup) - 完整的 CLI 安裝指南
- [API Authentication](https://inference.sh/docs/api/authentication) - API 金鑰管理
- [Secrets](https://inference.sh/docs/secrets/overview) - 憑證管理
