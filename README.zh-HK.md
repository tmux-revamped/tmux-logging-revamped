<div align="center">

# tmux-logging-revamped

<strong>將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-logging-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-logging-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-logging-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-logging-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-logging-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="logging-revamped 從選單開始即時記錄，在彈出視窗中跟隨它，並按標籤儲存回捲內容" width="800">
</p>

```console
$ logging-revamped save before-deploy
$ ls ~/.tmux/logs
tmux-main-0-0-20261117-092106-before-deploy.history
```

插件以三種方式將 tmux 窗格寫入檔案：隨輸出不斷增長的即時記錄、一次過儲存的完整捲動緩衝區，以及目前可見的畫面。它亦可追蹤、搜尋、複製、壓縮和清理這些檔案。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或以上 | 系列的最低版本：彈出視窗、窗格選項和提示中的 `%%%` 都需要它 |
| fzf | 可選 | 從搜尋結果中選擇一項 |
| gzip | 可選 | 用於 `compress` |
| 分頁器 | 可選 | 開啟搜尋結果，預設是 `less` |
| gum | 可選 | `logging-revamped` 的選單、表格和顏色；沒有它，所有命令都輸出純文字 |

### 安裝

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

然後按 `prefix + I`。不使用 TPM 時，複製儲存庫，並在 `~/.tmux.conf` 中執行它的入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

在複製的目錄中執行 `make install`，亦會把 `logging-revamped` 放入 `~/.local/bin`，並把它的 man 手冊和自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-logging-revamped/bin/logging-revamped doctor
```

## 用法

按 `prefix + M-l` 開啟記錄選單，其中列出全部 12 個動作。

為最常用的動作指定專用按鍵，並在目前窗格正在記錄時於狀態列顯示標記：

```tmux
set -g @logging_revamped_toggle_key 'P'
set -g @logging_revamped_save_key 'M-p'
set -g @logging_revamped_tail_key 'M-t'

set -g @logging_revamped_status_on 'REC'
set -g status-right '#{logging_status} %H:%M'
```

記錄最多保留兩星期，並在儲存捲動緩衝區時去除提示符行：

```tmux
set -g @logging_revamped_path '~/logs/tmux'
set -g @logging_revamped_retain_days '14'
set -g @logging_revamped_output_only '1'
```

清理不會自動執行：在選單中選擇「Prune old logs」，或執行 `logging-revamped prune`。

| 命令 | 作用 |
|:--------|:-------------|
| `logging-revamped apply` | 立即綁定按鍵和狀態指示；插件載入時入口點會執行它 |
| `logging-revamped list` | 列出 `apply` 會發送的每個指令，不作任何修改；`--json` 輸出一個物件 |
| `logging-revamped toggle` | 用 `pipe-pane` 開始或停止將目前窗格寫入檔案 |
| `logging-revamped save [LABEL]` | 將整個窗格歷史寫入 `.history` 檔案 |
| `logging-revamped screenshot [LABEL]` | 將可見畫面寫入 `.screen` 檔案 |
| `logging-revamped label` | 詢問一個標籤，加入檔案名稱，然後儲存捲動緩衝區 |
| `logging-revamped window` | 為目前視窗的每個窗格開始即時記錄 |
| `logging-revamped clear` | 清除目前窗格的捲動緩衝區 |
| `logging-revamped tail` | 在彈出視窗中用 `tail -f` 追蹤目前窗格的即時記錄 |
| `logging-revamped search [PATTERN]` | 在記錄目錄中 grep，在 fzf 中選取符合項目，並在分頁程式中開啟到該行 |
| `logging-revamped copy` | 將最新的未壓縮記錄載入 tmux 緩衝區和終端機剪貼簿 |
| `logging-revamped compress` | 對所有沒有窗格仍在寫入的記錄執行 `gzip` |
| `logging-revamped prune` | 按保留選項的設定，以日數或數目刪除記錄 |
| `logging-revamped status` | 列出此窗格的指示文字 |
| `logging-revamped doctor` | 每個依賴一行，包括記錄檔資料夾、gzip、fzf 和保持不變的按鍵 |
| `logging-revamped version` | 版本，然後是 tmux 版本 |
| `logging-revamped help` | 說明頁；`man logging-revamped` 記錄相同的命令和設定 |
| `logging-revamped` | 在終端機上顯示選單 |

檔案名稱由工作階段、視窗和窗格、`YYYYmmdd-HHMMSS` 格式的時間戳記以及類型組成，例如 `tmux-main-1-0-20260622-143005.history`。每一部分都只保留字母、數字、`.`、`_` 和 `-`，所以名為 `feature/login` 的工作階段亦不會跑出記錄目錄。

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@logging_revamped_path` | `~/.tmux/logs` | 存放所有檔案的目錄；首次需要時以 700 權限建立 |
| `@logging_revamped_color` | `0` | 設為 `1` 時，在儲存的捲動緩衝區和畫面中保留 ANSI 顏色序列 |
| `@logging_revamped_rolling` | `0` | 設為 `1` 時，即時記錄附加到每個工作階段一個的 `tmux-<session>-session.log` |
| `@logging_revamped_output_only` | `0` | 設為 `1` 時，從儲存的捲動緩衝區和畫面中去除符合提示符模式的行 |
| `@logging_revamped_prompt_pattern` | `^[[:space:]]*[#$%>] ` | 只輸出模式要去除的行所用的延伸正規表示式 |
| `@logging_revamped_retain_days` | `0` | 大於 0 時，清理會刪除早於此日數的未壓縮記錄 |
| `@logging_revamped_retain_max` | `0` | 大於 0 時，清理只保留最新的這個數目的記錄 |
| `@logging_revamped_pager` | `less` | 開啟搜尋符合項目的分頁程式，以 `<pager> +<line> -- <file>` 方式呼叫 |
| `@logging_revamped_status_on` | `*` | 目前窗格正在記錄時 `#{logging_status}` 顯示的文字 |
| `@logging_revamped_status_off` | 空 | 其他情況下 `#{logging_status}` 顯示的文字 |

每個按鍵選項接受一個 tmux 按鍵名稱。值為空或 `off` 時不綁定任何按鍵。

| 選項 | 預設值 | 動作 |
|:-----|:-------|:-----|
| `@logging_revamped_menu_key` | `M-l` | 記錄選單 |
| `@logging_revamped_toggle_key` | 空 | 切換即時記錄 |
| `@logging_revamped_save_key` | 空 | 儲存捲動緩衝區 |
| `@logging_revamped_screenshot_key` | 空 | 儲存畫面 |
| `@logging_revamped_label_key` | 空 | 加標籤儲存 |
| `@logging_revamped_window_key` | 空 | 記錄整個視窗 |
| `@logging_revamped_clear_key` | 空 | 清除歷史 |
| `@logging_revamped_tail_key` | 空 | 即時追蹤 |
| `@logging_revamped_search_key` | 空 | 搜尋記錄 |

複製、壓縮、清理和診斷沒有按鍵選項，從選單中使用。

每個選項亦可以用帶連字號的命令選項（例如 `--path ~/logs`）和環境變數（例如 `LOGGING_REVAMPED_PATH`）設定；命令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示使用預設值。`doctor` 會指出數值無法識別的設定。傳給 `apply` 的選項會隨每個綁定一起生效。

插件自己寫入三個選項：窗格選項 `@logging_revamped_file` 是正在記錄的窗格寫入的檔案，全域的 `@logging_revamped_prompt` 和 `@logging_revamped_search_pattern` 把輸入的回覆交給工具。

<a id="運作原理"></a>

## 運作原理

[`logging-revamped.tmux`](logging-revamped.tmux) 在 tmux 載入插件時執行一次 `bin/logging-revamped apply`。它用一次 tmux 呼叫，把每個已設定的按鍵綁定到帶有工具和動作名稱的 `run-shell`，把選單鍵綁定到選單本身，所以在你按鍵之前甚麼都不會執行。

它亦會將 `status-left` 和 `status-right` 中的 `#{logging_status}` 換成由兩個狀態選項組成的 `#{?pane_pipe,on,off}` 格式。這個格式由 tmux 自行繪製，所以指示器不會在每次重繪時啟動程序。請在插件載入前設定狀態選項，或在修改後重新載入設定。

即時記錄就是在 umask 077 下執行 `cat >>` 寫入檔案的 `pipe-pane`。儲存捲動緩衝區和畫面使用 `capture-pane`，並去除每行末尾的空白。標籤和搜尋提示透過 `%%%` 將輸入的文字交給插件選項，所以回覆中的引號和 `#()` 既不會進入 shell，亦不會進入格式。

<a id="畫面"></a>

## 畫面

<details>
<summary>所有畫面，在真實的 tmux 中用 <code>make screens</code> 錄製，每個按鍵顯示在狀態列上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/logging-menu.png" alt="logging-revamped：prefix M-l 開啟記錄選單"><br><sub><code>prefix M-l</code> 開啟記錄選單，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/live.png" alt="logging-revamped：即時記錄開始，狀態列隨之提示"><br><sub>即時記錄開始，狀態列隨之提示，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/tail.png" alt="logging-revamped：prefix M-t 在彈出視窗中跟隨即時記錄"><br><sub><code>prefix M-t</code> 在彈出視窗中跟隨即時記錄，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/saved.png" alt="logging-revamped：save 按標籤儲存回捲內容"><br><sub><code>save</code> 按標籤儲存回捲內容，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="logging-revamped：選單"><br><sub>選單，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="logging-revamped：doctor"><br><sub><code>doctor</code>，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/label.png" alt="logging-revamped：標籤鍵詢問標籤"><br><sub>標籤鍵詢問標籤，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/search.png" alt="logging-revamped：搜尋鍵列出所有符合項目"><br><sub>搜尋鍵列出所有符合項目，來自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/match.png" alt="logging-revamped：選中的項目在分頁器中定位到所在行"><br><sub>選中的項目在分頁器中定位到所在行，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/window.png" alt="logging-revamped：視窗鍵記錄每個窗格"><br><sub>視窗鍵記錄每個窗格，來自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/screenshot.png" alt="logging-revamped：從選單儲存畫面"><br><sub>從選單儲存畫面，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clear.png" alt="logging-revamped：從選單清除記錄"><br><sub>從選單清除記錄，來自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="logging-revamped：從選單複製最新記錄"><br><sub>從選單複製最新記錄，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/compress.png" alt="logging-revamped：從選單壓縮記錄"><br><sub>從選單壓縮記錄，來自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/prune.png" alt="logging-revamped：從選單清理舊記錄"><br><sub>從選單清理舊記錄，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="logging-revamped：list 列出每個綁定"><br><sub><code>list</code> 列出每個綁定，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="logging-revamped：status"><br><sub><code>status</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="logging-revamped：沒有 gum 的選單"><br><sub>沒有 gum 的選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="logging-revamped：從選單執行 doctor"><br><sub>從選單執行 <code>doctor</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="logging-revamped：版本"><br><sub>版本，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="logging-revamped：不明命令"><br><sub>不明命令，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="logging-revamped：六種主題下的標題"><br><sub>六種主題下的標題，來自 <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="logging-revamped：說明頁"><br><sub>說明頁，來自 <code>help.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="logging-revamped：來自 LOGGING_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>LOGGING_REVAMPED_ACCENT</code> 的強調色，來自 <code>stills.tape</code></sub></td>
</tr>
</table>

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

在 macOS 上，執行 `brew bundle` 會根據 [`Brewfile`](Brewfile) 安裝這些目標用到的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **本插件**，將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
