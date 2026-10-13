# 容器感知 CLI 審閱修復規格書 (Container-Aware CLI Review Fixes Spec)

**PR:** NousResearch/hermes-agent#7543
**審閱:** cursor[bot] bugbot 審閱 (4094049442) + 前兩輪審閱
**日期:** 2026-04-12
**分支:** `feat/container-aware-cli-clean`

## 審閱問題摘要

在三輪 bugbot 審閱中共提出了六個問題。其中三個已在中間提交中修復 (38277a6a, 726cf90f)。本規格書旨在解決這些審閱中浮現的剩餘設計疑慮，並根據訪談決定簡化實作。

| # | 問題 | 嚴重性 | 狀態 |
|---|-------|----------|--------|
| 1 | `os.execvp` 重試迴圈無法到達 | 中 | 已在 79e8cd12 修復 (切換至 subprocess.run) |
| 2 | 多餘的 `shutil.which("sudo")` | 中 | 已在 38277a6a 修復 (重用 `sudo` 變數) |
| 3 | 更新符號連結時缺少 `chown -h` | 低 | 已在 38277a6a 修復 |
| 4 | 在 `parse_args()` 之後的容器路由 | 高 | 已在 726cf90f 修復 |
| 5 | 硬編碼的 `/home/${user}` | 中 | 已在 726cf90f 修復 |
| 6 | 群組成員身分未受 `container.enable` 管控 | 低 | 已在 726cf90f 修復 |

機械式的修復已經完成，但整體設計仍需修訂。重試迴圈、吞掉錯誤以及程序模型存在比 bugbot 標記的更深層問題。

---

## 規格：修訂後的 `_exec_in_container`

### 設計原則

1. **讓它崩潰 (Let it crash)。** 不進行靜默回退。如果 `.container-mode` 存在但發生錯誤，錯誤應自然傳播（Python 追蹤資訊）。跳過容器路由的唯一情況是 `.container-mode` 不存在或 `HERMES_DEV=1`。
2. **不重試。** 探測一次 sudo，執行一次 exec。如果失敗，docker/podman 的標準錯誤 (stderr) 將原封不動地傳達給使用者。
3. **完全透明。** 不封裝錯誤、不加前綴、不顯示進度指示器。Docker 的輸出直接通過。
4. **正常流程使用 `os.execvp`。** 完全替換 Python 程序，以便在互動式工作階段中沒有閒置的父程序。注意：`execvp` 成功時絕不返回（程序已被替換），失敗時會引發 `OSError`（它不返回值）。根據定義，容器程序的結束代碼即為程序的結束代碼——不需要顯式的傳播。
5. **針對「讓它崩潰」的一個易於閱讀的例外。** 來自 sudo 探測的 `subprocess.TimeoutExpired` 會被特別擷取並顯示可讀的訊息，因為針對「您的 Docker 守護行程反應遲緩」顯示原始追蹤資訊會讓人困惑。所有其他例外情況則自然傳播。

### 執行流程

```
1. get_container_exec_info()
   - HERMES_DEV=1 → 回傳 None (跳過路由)
   - 在容器內 → 回傳 None (跳過路由)
   - .container-mode 不存在 → 回傳 None (跳過路由)
   - .container-mode 存在 → 解析並回傳 dict
   - .container-mode 存在但格式錯誤/無法讀取 → 讓它崩潰 (不使用 try/except)

2. _exec_in_container(container_info, sys.argv[1:])
   a. shutil.which(backend) → 如果為 None，列印 "{backend} not found on PATH" 並執行 sys.exit(1)
   b. Sudo 探測：subprocess.run([runtime, "inspect", "--format", "ok", container_name], timeout=15)
      - 如果成功 → needs_sudo = False
      - 如果失敗 → 嘗試 subprocess.run([sudo, "-n", runtime, "inspect", ...], timeout=15)
        - 如果成功 → needs_sudo = True
        - 如果失敗 → 列印帶有 sudoers 提示的錯誤（包括為什麼需要 -n）並執行 sys.exit(1)
      - 如果 TimeoutExpired → 特別擷取，列印關於守護行程反應遲緩的可讀訊息
   c. 建立 exec_cmd: [sudo? + runtime, "exec", tty_flags, "-u", exec_user, env_flags, container, hermes_bin, *cli_args]
   d. os.execvp(exec_cmd[0], exec_cmd)
      - 成功時：程序被替換——Python 已消失，容器結束代碼「就是」程序結束代碼
      - 發生 OSError 時：讓它崩潰 (自然顯示追蹤資訊)
```

### `hermes_cli/main.py` 的變更

#### `_exec_in_container` — 重寫

移除：
- 整個重試迴圈 (`max_retries`, `for attempt in range(...)`)
- 進度指示器邏輯 (`"Waiting for container..."`, 點點)
- 結束代碼分類 (125/126/127 處理)
- 用於 exec 呼叫的 `subprocess.run` (僅為 sudo 探測保留它)
- 特定的 TTY vs 非 TTY 重試次數
- `time` 匯入 (不再需要)

變更：
- 使用 `os.execvp(exec_cmd[0], exec_cmd)` 作為最終呼叫
- 僅為 sudo 探測保留 `subprocess` 匯入
- 保留用於 `-it` vs `-i` 旗標的 TTY 偵測
- 保留環境變數轉發 (TERM, COLORTERM, LANG, LC_ALL)
- 原樣保留 sudo 探測 (這是唯一的「智慧」部分)
- 將探測 `timeout` 從 5s 增加到 15s —— 負載過重的機器上的冷啟動 podman 需要更多緩衝時間
- 在兩次探測呼叫中特別擷取 `subprocess.TimeoutExpired` —— 列印關於守護行程無回應的可讀訊息，而不是原始追蹤資訊
- 擴充 sudoers 提示錯誤訊息，解釋 *為什麼* 需要 `-n` (非互動式)：密碼提示會使 CLI 掛起或破壞管道命令

該函式大致變為：

```python
def _exec_in_container(container_info: dict, cli_args: list):
    """用受管理容器內的指令替換當前程序。

    探測是否需要 sudo (rootful 容器)，然後 os.execvp
    進入容器。如果 exec 失敗，OS 錯誤將自然傳播。
    """
    import shutil
    import subprocess

    backend = container_info["backend"]
    container_name = container_info["container_name"]
    exec_user = container_info["exec_user"]
    hermes_bin = container_info["hermes_bin"]

    runtime = shutil.which(backend)
    if not runtime:
        print(f"Error: {backend} not found on PATH. Cannot route to container.",
              file=sys.stderr)
        sys.exit(1)

    # 探測我們是否需要 sudo 才能看到 rootful 容器。
    # 逾時時間為 15 秒 —— 負載過重的機器上的冷啟動 podman 可能需要一段時間。
    # 特別擷取 TimeoutExpired 以顯示易於閱讀的訊息；
    # 所有其他例外情況則自然傳播。
    needs_sudo = False
    sudo = None
    try:
        probe = subprocess.run(
            [runtime, "inspect", "--format", "ok", container_name],
            capture_output=True, text=True, timeout=15,
        )
    except subprocess.TimeoutExpired:
        print(
            f"Error: timed out waiting for {backend} to respond.\n"
            f"The {backend} daemon may be unresponsive or starting up.",
            file=sys.stderr,
        )
        sys.exit(1)

    if probe.returncode != 0:
        sudo = shutil.which("sudo")
        if sudo:
            try:
                probe2 = subprocess.run(
                    [sudo, "-n", runtime, "inspect", "--format", "ok", container_name],
                    capture_output=True, text=True, timeout=15,
                )
            except subprocess.TimeoutExpired:
                print(
                    f"Error: timed out waiting for sudo {backend} to respond.",
                    file=sys.stderr,
                )
                sys.exit(1)

            if probe2.returncode == 0:
                needs_sudo = True
            else:
                print(
                    f"Error: container '{container_name}' not found via {backend}.\n"
                    f"\n"
                    f"The NixOS service runs the container as root. Your user cannot\n"
                    f"see it because {backend} uses per-user namespaces.\n"
                    f"\n"
                    f"Fix: grant passwordless sudo for {backend}. The -n (non-interactive)\n"
                    f"flag is required because the CLI calls sudo non-interactively —\n"
                    f"a password prompt would hang or break piped commands:\n"
                    f"\n"
                    f'  security.sudo.extraRules = [{{\n'
                    f'    users = [ "{os.getenv("USER", "your-user")}" ];\n'
                    f'    commands = [{{ command = "{runtime}"; options = [ "NOPASSWD" ]; }}];\n'
                    f'  }}];\n'
                    f"\n"
                    f"Or run: sudo hermes {' '.join(cli_args)}",
                    file=sys.stderr,
                )
                sys.exit(1)
        else:
            print(
                f"Error: container '{container_name}' not found via {backend}.\n"
                f"The container may be running under root. Try: sudo hermes {' '.join(cli_args)}",
                file=sys.stderr,
            )
            sys.exit(1)

    is_tty = sys.stdin.isatty()
    tty_flags = ["-it"] if is_tty else ["-i"]

    env_flags = []
    for var in ("TERM", "COLORTERM", "LANG", "LC_ALL"):
        val = os.environ.get(var)
        if val:
            env_flags.extend(["-e", f"{var}={val}"])

    cmd_prefix = [sudo, "-n", runtime] if needs_sudo else [runtime]
    exec_cmd = (
        cmd_prefix + ["exec"]
        + tty_flags
        + ["-u", exec_user]
        + env_flags
        + [container_name, hermes_bin]
        + cli_args
    )

    # execvp 完全替換此程序 —— 成功時絕不返回。
    # 失敗時它會引發 OSError，並自然傳播。
    os.execvp(exec_cmd[0], exec_cmd)
```

#### `main()` 中的容器路由呼叫點 — 移除 try/except

目前：
```python
try:
    from hermes_cli.config import get_container_exec_info
    container_info = get_container_exec_info()
    if container_info:
        _exec_in_container(container_info, sys.argv[1:])
        sys.exit(1)  # 如果到達這裡，表示 exec 失敗
except SystemExit:
    raise
except Exception:
    pass  # 容器路由不可用，於本地繼續執行
```

修訂後：
```python
from hermes_cli.config import get_container_exec_info
container_info = get_container_exec_info()
if container_info:
    _exec_in_container(container_info, sys.argv[1:])
    # 無法到達：os.execvp 成功時絕不返回 (程序已被替換)
    # 且失敗時會引發 OSError (作為追蹤資訊傳播)。
    # 此行僅作為防禦性斷言存在。
    sys.exit(1)
```

不使用 try/except。如果 `.container-mode` 不存在，`get_container_exec_info()` 會回傳 `None` 並跳過路由。如果它存在但毀損，例外情況將隨自然追蹤資訊傳播。

注意：在所有路徑中，`_exec_in_container` 之後的 `sys.exit(1)` 都是無效程式碼 —— `os.execvp` 要麼替換程序，要麼引發例外。保留它作為防備性斷言並附上標記為無法到達的註釋，而非實際的錯誤處理。

### `hermes_cli/config.py` 的變更

#### `get_container_exec_info` — 移除內層 try/except

目前的程式碼會擷取 `(OSError, IOError)` 並回傳 `None`。這會靜默隱藏權限錯誤、損壞的檔案等。

變更：移除讀取檔案周圍的 try/except。保留針對 `HERMES_DEV=1` 和 `_is_inside_container()` 的提前回傳。當 `.container-mode` 不存在時，來自 `open()` 的 `FileNotFoundError` 仍應回傳 `None`（這是「容器模式未啟用」的情況）。所有其他例外情況則自然傳播。

```python
def get_container_exec_info() -> Optional[dict]:
    if os.environ.get("HERMES_DEV") == "1":
        return None
    if _is_inside_container():
        return None

    container_mode_file = get_hermes_home() / ".container-mode"

    try:
        with open(container_mode_file, "r") as f:
            # ... 解析 key=value 行 ...
    except FileNotFoundError:
        return None
    # 所有其他例外情況 (PermissionError, 格式錯誤的資料等) 自然傳播

    return { ... }
```

---

## 規格：NixOS 模組變更

### 符號連結建立 — 簡化為兩個分支

目前：4 個分支（符號連結存在、目錄存在、其他檔案、不存在）。

修訂後：2 個分支。

```bash
if [ -d "${symlinkPath}" ] && [ ! -L "${symlinkPath}" ]; then
  # 真實目錄 — 備份後建立符號連結
  _backup="${symlinkPath}.bak.$(date +%s)"
  echo "hermes-agent: backing up existing ${symlinkPath} to $_backup"
  mv "${symlinkPath}" "$_backup"
fi
# 對於其他所有情況 (符號連結、不存在等) — 直接強制建立
ln -sfn "${target}" "${symlinkPath}"
chown -h ${user}:${cfg.group} "${symlinkPath}"
```

`ln -sfn` 處理：現有符號連結（替換）、不存在（建立），以及在上述 `mv` 之後（建立）。唯一需要特殊處理的情況是真實目錄，因為 `ln -sfn` 無法原子性地替換目錄。

注意：在 `[ -d ... ]` 檢查和 `mv` 之間存在理論上的競態條件（可能有東西在此期間建立/移除目錄）。實務上，這是作為 root 執行的 NixOS 啟動腳本，在 `nixos-rebuild switch` 期間執行 —— 此時不應有其他程序動到 `~/.hermes`。不值得為此添加鎖定機制。

### Sudoers — 記錄文件，不要自動配置

**不要**將 `security.sudo.extraRules` 添加到模組中。在模組的描述/註釋以及 CLI 在 sudo 探測失敗時列印的錯誤訊息中記錄 sudoers 要求。

### 群組成員身分控管 — 保持原樣

726cf90f 中的修復 (`cfg.container.enable && cfg.container.hostUsers != []`) 是正確的。當容器模式停用時，殘留的群組成員身分是無害的。不需要清理。

---

## 規格：測試重寫

現有的測試檔案 (`tests/hermes_cli/test_container_aware_cli.py`) 有 16 個測試。隨著 exec 模型的簡化，其中一些已過時。

### 保留的測試 (根據需要更新)

- `test_is_inside_container_dockerenv` — 無變更
- `test_is_inside_container_containerenv` — 無變更
- `test_is_inside_container_cgroup_docker` — 無變更
- `test_is_inside_container_false_on_host` — 無變更
- `test_get_container_exec_info_returns_metadata` — 無變更
- `test_get_container_exec_info_none_inside_container` — 無變更
- `test_get_container_exec_info_none_without_file` — 無變更
- `test_get_container_exec_info_skipped_when_hermes_dev` — 無變更
- `test_get_container_exec_info_not_skipped_when_hermes_dev_zero` — 無變更
- `test_get_container_exec_info_defaults` — 無變更
- `test_get_container_exec_info_docker_backend` — 無變更

### 新增的測試

- `test_get_container_exec_info_crashes_on_permission_error` — 驗證 `PermissionError` 自然傳播 (不靜默回傳 `None`)
- `test_exec_in_container_calls_execvp` — 驗證是否使用正確的引數呼叫 `os.execvp` (runtime, tty flags, user, env, container, binary, cli args)
- `test_exec_in_container_sudo_probe_sets_prefix` — 驗證當第一次探測失敗且 sudo 探測成功時，`os.execvp` 是以 `sudo -n` 前綴呼叫的
- `test_exec_in_container_no_runtime_hard_fails` — 保留現有測試，驗證當 `shutil.which` 回傳 None 時執行 `sys.exit(1)`
- `test_exec_in_container_non_tty_uses_i_only` — 更新以檢查 `os.execvp` 引數而非 `subprocess.run` 引數
- `test_exec_in_container_probe_timeout_prints_message` — 驗證探測發生的 `subprocess.TimeoutExpired` 會產生易於閱讀的錯誤訊息和 `sys.exit(1)`，而非原始追蹤資訊
- `test_exec_in_container_container_not_running_no_sudo` — 驗證 runtime 存在（`shutil.which` 回傳路徑）但探測回傳非零且無 sudo 可用的路徑。應列印「container may be running under root」錯誤。這與 `no_runtime_hard_fails` 不同，後者涵蓋 `shutil.which` 回傳 None 的情況。

### 刪除的測試

- `test_exec_in_container_tty_retries_on_container_failure` — 重試迴圈已移除
- `test_exec_in_container_non_tty_retries_silently_exits_126` — 重試迴圈已移除
- `test_exec_in_container_propagates_hermes_exit_code` — 沒有可檢查結束代碼的 subprocess.run；execvp 會替換程序。注意：結束代碼傳播仍然正常運作 —— 當 `os.execvp` 成功時，容器的程序將 *變為* 此程序，因此其結束代碼在 OS 語義上即為該程序的結束代碼。不需要應用程式碼，也不需要測試。該函式文件字串中的註釋記錄了此意圖以供未來讀者參考。

---

## 超出範圍

- 在 NixOS 模組中自動配置 sudoers 規則
- 對 `get_container_exec_info` 解析邏輯進行除縮小 try/except 範圍外的任何變更
- 變更 `.container-mode` 檔案格式
- 變更 `HERMES_DEV=1` 繞過機制
- 變更容器偵測邏輯 (`_is_inside_container`)
