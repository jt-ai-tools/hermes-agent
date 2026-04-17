Hermes Agent 的 Homebrew 打包說明。

請使用 `packaging/homebrew/hermes-agent.rb` 作為 Tap 或 `homebrew-core` 的起始點。

關鍵決策：
- 穩定版本應針對 GitHub Release 中附加的語法版本 (semver) 命名之 sdist 資產，而非 CalVer 標籤的 tarball。
- `faster-whisper` 現在位於 `voice` 額外組件中，這可以防止僅限 wheel 的傳遞依賴項進入基礎 Homebrew Formula。
- 包裝器匯出 `HERMES_BUNDLED_SKILLS`、`HERMES_OPTIONAL_SKILLS` 和 `HERMES_MANAGED=homebrew`，以便封裝安裝能保留執行時期資產，並將升級交由 Homebrew 處理。

典型的更新流程：
1. 提升 Formula 的 `url`、`version` 和 `sha256`。
2. 使用 `brew update-python-resources --print-only hermes-agent` 更新 Python 資源。
3. 保持 `ignore_packages: %w[certifi cryptography pydantic]`。
4. 驗證 `brew audit --new --strict hermes-agent` 和 `brew test hermes-agent`。
