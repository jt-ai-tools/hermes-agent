---
name: linear
description: 透過 GraphQL API 管理 Linear 的議題 (issues)、專案和團隊。建立、更新、搜尋及整理議題。使用 API 金鑰認證 (無需 OAuth)。所有操作均透過 curl 完成 — 無需額外依賴。
version: 1.0.0
author: Hermes Agent
license: MIT
prerequisites:
  env_vars: [LINEAR_API_KEY]
  commands: [curl]
metadata:
  hermes:
    tags: [Linear, Project Management, Issues, GraphQL, API, Productivity]
---

# Linear — 議題與專案管理

使用 `curl` 透過 GraphQL API 直接管理 Linear 的議題、專案和團隊。無需 MCP 伺服器、OAuth 流程或額外依賴。

## 設定

1. 從 **Linear Settings > API > Personal API keys** 取得個人 API 金鑰
2. 在您的環境中設定 `LINEAR_API_KEY` (透過 `hermes setup` 或您的環境變數設定檔)

## API 基礎知識

- **端點 (Endpoint):** `https://api.linear.app/graphql` (POST)
- **驗證標頭 (Auth header):** `Authorization: $LINEAR_API_KEY` (API 金鑰無需 "Bearer" 前綴)
- **所有請求皆為 POST**，且帶有 `Content-Type: application/json`
- **UUID 和短識別碼** (例如：`ENG-123`) 皆可用於 `issue(id:)`

基礎 curl 模式：
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { id name } }"}' | python3 -m json.tool
```

## 工作流狀態 (Workflow States)

Linear 使用帶有 `type` 欄位的 `WorkflowState` 物件。**共有 6 種狀態類型：**

| 類型 | 描述 |
|------|-------------|
| `triage` | 需要審查的傳入議題 |
| `backlog` | 已確認但尚未計劃 |
| `unstarted` | 已計劃/準備就緒但尚未開始 |
| `started` | 正在積極處理中 |
| `completed` | 已完成 |
| `canceled` | 取消 (不會執行) |

每個團隊都有自己命名的狀態 (例如："In Progress" 的類型是 `started`)。若要更改議題狀態，您需要目標狀態的 `stateId` (UUID) — 請先查詢工作流狀態。

**優先級 (Priority) 數值：** 0 = 無、1 = 緊急、2 = 高、3 = 中、4 = 低

## 常見查詢 (Queries)

### 取得目前使用者
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { id name email } }"}' | python3 -m json.tool
```

### 列出團隊
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ teams { nodes { id name key } } }"}' | python3 -m json.tool
```

### 列出團隊的工作流狀態
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ workflowStates(filter: { team: { key: { eq: \"ENG\" } } }) { nodes { id name type } } }"}' | python3 -m json.tool
```

### 列出議題 (前 20 個)
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issues(first: 20) { nodes { identifier title priority state { name type } assignee { name } team { key } url } pageInfo { hasNextPage endCursor } } }"}' | python3 -m json.tool
```

### 列出指派給我的議題
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { assignedIssues(first: 25) { nodes { identifier title state { name type } priority url } } } }"}' | python3 -m json.tool
```

### 取得單一議題 (透過識別碼如 ENG-123)
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issue(id: \"ENG-123\") { id identifier title description priority state { id name type } assignee { id name } team { key } project { name } labels { nodes { name } } comments { nodes { body user { name } createdAt } } url } }"}' | python3 -m json.tool
```

### 透過文字搜尋議題
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issueSearch(query: \"bug login\", first: 10) { nodes { identifier title state { name } assignee { name } url } } }"}' | python3 -m json.tool
```

### 依狀態類型篩選議題
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issues(filter: { state: { type: { in: [\"started\"] } } }, first: 20) { nodes { identifier title state { name } assignee { name } } } }"}' | python3 -m json.tool
```

### 依團隊和受指派者篩選
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issues(filter: { team: { key: { eq: \"ENG\" } }, assignee: { email: { eq: \"user@example.com\" } } }, first: 20) { nodes { identifier title state { name } priority } } }"}' | python3 -m json.tool
```

### 列出專案
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ projects(first: 20) { nodes { id name description progress lead { name } teams { nodes { key } } url } } }"}' | python3 -m json.tool
```

### 列出團隊成員
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ users { nodes { id name email active } } }"}' | python3 -m json.tool
```

### 列出標籤
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issueLabels { nodes { id name color } } }"}' | python3 -m json.tool
```

## 常見變更操作 (Mutations)

### 建立議題
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier title url } } }",
    "variables": {
      "input": {
        "teamId": "TEAM_UUID",
        "title": "Fix login bug",
        "description": "Users cannot login with SSO",
        "priority": 2
      }
    }
  }' | python3 -m json.tool
```

### 更新議題狀態
先從上面的工作流狀態查詢取得目標狀態的 UUID，然後：
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ENG-123\", input: { stateId: \"STATE_UUID\" }) { success issue { identifier state { name type } } } }"}' | python3 -m json.tool
```

### 指派議題
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ENG-123\", input: { assigneeId: \"USER_UUID\" }) { success issue { identifier assignee { name } } } }"}' | python3 -m json.tool
```

### 設定優先級
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ENG-123\", input: { priority: 1 }) { success issue { identifier priority } } }"}' | python3 -m json.tool
```

### 新增留言
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { commentCreate(input: { issueId: \"ISSUE_UUID\", body: \"Investigated. Root cause is X.\" }) { success comment { id body } } }"}' | python3 -m json.tool
```

### 設定截止日期
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ENG-123\", input: { dueDate: \"2026-04-01\" }) { success issue { identifier dueDate } } }"}' | python3 -m json.tool
```

### 為議題新增標籤
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ENG-123\", input: { labelIds: [\"LABEL_UUID_1\", \"LABEL_UUID_2\"] }) { success issue { identifier labels { nodes { name } } } } }"}' | python3 -m json.tool
```

### 將議題加入專案
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ENG-123\", input: { projectId: \"PROJECT_UUID\" }) { success issue { identifier project { name } } } }"}' | python3 -m json.tool
```

### 建立專案
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation($input: ProjectCreateInput!) { projectCreate(input: $input) { success project { id name url } } }",
    "variables": {
      "input": {
        "name": "Q2 Auth Overhaul",
        "description": "Replace legacy auth with OAuth2 and PKCE",
        "teamIds": ["TEAM_UUID"]
      }
    }
  }' | python3 -m json.tool
```

## 分頁 (Pagination)

Linear 使用 Relay 風格的游標分頁：

```bash
# 第一頁
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issues(first: 20) { nodes { identifier title } pageInfo { hasNextPage endCursor } } }"}' | python3 -m json.tool

# 下一頁 — 使用上一次回應中的 endCursor
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issues(first: 20, after: \"CURSOR_FROM_PREVIOUS\") { nodes { identifier title } pageInfo { hasNextPage endCursor } } }"}' | python3 -m json.tool
```

預設分頁大小：50。最大：250。請務必使用 `first: N` 來限制結果。

## 篩選參考 (Filtering Reference)

比較算子：`eq`, `neq`, `in`, `nin`, `lt`, `lte`, `gt`, `gte`, `contains`, `startsWith`, `containsIgnoreCase`

使用 `or: [...]` 來組合篩選器以實現 OR 邏輯 (篩選物件內預設為 AND)。

## 典型工作流程

1. **查詢團隊**以取得團隊 ID 和 Key
2. 為目標團隊**查詢工作流狀態**以取得狀態 UUID
3. **列出或搜尋議題**以找到需要處理的工作
4. 使用團隊 ID、標題、描述、優先級**建立議題**
5. 透過將 `stateId` 設定為目標工作流狀態來**更新狀態**
6. **新增留言**以追蹤進度
7. 將 `stateId` 設定為團隊的 "completed" 類型狀態以**標記為完成**

## 速率限制 (Rate Limits)

- 每個 API 金鑰每小時 5,000 次請求
- 每小時 3,000,000 點複雜度點數
- 使用 `first: N` 來限制結果並降低複雜度成本
- 監控 `X-RateLimit-Requests-Remaining` 回應標頭

## 重要注意事項

- 執行 API 呼叫時，請務必搭配 `curl` 使用 `terminal` 工具 — 請勿使用 `web_extract` 或 `browser`
- 務必檢查 GraphQL 回應中的 `errors` 陣列 — HTTP 200 仍可能包含錯誤
- 若建立議題時省略 `stateId`，Linear 預設會使用第一個 backlog 狀態
- `description` 欄位支援 Markdown
- 使用 `python3 -m json.tool` 或 `jq` 來格式化 JSON 回應以利閱讀
