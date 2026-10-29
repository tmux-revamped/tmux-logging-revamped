<div align="center">

# tmux-logging-revamped

<strong>將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文（香港）

[![family](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/family.yml?branch=main&style=flat-square&label=family)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/family.yml)
[![tests](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/tests.yml?branch=main&style=flat-square&label=tests)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-logging-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-logging-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-logging-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-logging-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-logging-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#installation">安裝</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">設定</a> |
  <a href="#key-bindings">按鍵綁定</a> |
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**12** 個選單動作，**19** 個選項，預設只綁定 **1** 個按鍵，支援 tmux **3.2** 或以上版本。

---

<a id="what-it-does"></a>

## 功能

插件以三種方式將 tmux 窗格寫入檔案：隨輸出不斷增長的即時記錄、一次過儲存的完整捲動緩衝區，以及目前可見的畫面。它亦可追蹤、搜尋、複製、壓縮和清理這些檔案。

| 動作 | 作用 |
|:-----|:-----|
| 切換即時記錄 | 用 `pipe-pane` 開始或停止將目前窗格寫入檔案 |
| 儲存捲動緩衝區 | 將整個窗格歷史寫入 `.history` 檔案 |
| 儲存畫面 | 將可見畫面寫入 `.screen` 檔案 |
| 加標籤儲存 | 詢問一個標籤，加入檔案名稱，然後儲存捲動緩衝區 |
| 記錄整個視窗 | 為目前視窗的每個窗格開始即時記錄 |
| 清除歷史 | 清除目前窗格的捲動緩衝區 |
| 即時追蹤 | 在彈出視窗中用 `tail -f` 追蹤目前窗格的即時記錄 |
| 搜尋記錄 | 在記錄目錄中 grep，在 fzf 中選取符合項目，並在分頁程式中開啟到該行 |
| 複製最新記錄 | 將最新的未壓縮記錄載入 tmux 緩衝區和終端機剪貼簿 |
| 壓縮記錄 | 對所有沒有窗格仍在寫入的記錄執行 `gzip` |
| 清理舊記錄 | 按保留選項的設定，以日數或數目刪除記錄 |
| 診斷 | 顯示平台、記錄路徑及其是否可寫入、模式選項，以及找到哪些工具 |

檔案名稱由工作階段、視窗和窗格、`YYYYmmdd-HHMMSS` 格式的時間戳記以及類型組成，例如 `tmux-main-1-0-20260622-143005.history`。每一部分都只保留字母、數字、`.`、`_` 和 `-`，所以名為 `feature/login` 的工作階段亦不會跑出記錄目錄。

<a id="requirements"></a>

## 系統要求

| 要求 | 版本 |
|:-----|:-----|
| tmux | 3.2 或以上 |
| bash | 3.2 或以上 |
| fzf | 任何版本，只有搜尋需要 |
| gzip | 任何版本，只有壓縮需要 |
| less | 任何版本，搜尋的預設分頁程式 |

可在 Linux 和 macOS 上執行，支援 BSD、GNU 或 uutils coreutils。即時追蹤、搜尋和診斷在 `display-popup` 中開啟，複製使用 `load-buffer -w`，兩者都需要 tmux 3.2。

<a id="installation"></a>

## 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，將插件加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

手動安裝時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

<a id="usage"></a>

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

只有在選單中選擇「Prune old logs」時才會執行清理。

<a id="configuration"></a>

## 設定

### 行為

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

### 按鍵

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

### 內部狀態

以下選項由插件自行寫入，請勿設定。

| 選項 | 存放內容 |
|:-----|:---------|
| `@logging_revamped_file_<pane>` | 正在即時記錄的窗格寫入的檔案，以窗格 ID 為鍵，字母和數字以外的字元都換成 `_`，例如 `%3` 對應 `_3` |
| `@logging_revamped_search_pattern` | 由搜尋提示傳給選擇器彈出視窗的搜尋模式 |
| `@logging_revamped_prompt` | 在標籤或搜尋提示中輸入的文字，讀取一次後刪除 |
| `@logging_status` | 目前的狀態文字，只在執行 `src/logging.sh status` 時寫入；狀態列不會讀取它 |

<a id="key-bindings"></a>

## 按鍵綁定

| 按鍵 | 動作 | 預設 |
|:-----|:-----|:-----|
| `prefix + M-l` | 記錄選單 | 已綁定 |
| `@logging_revamped_<action>_key` | 按鍵表中對應的動作 | 未綁定 |

2.0.0 版將選單由 `M-m` 移到 `M-l`，並取消了其他所有按鍵的綁定。要還原舊的配置：

```tmux
set -g @logging_revamped_menu_key 'M-m'
set -g @logging_revamped_toggle_key 'P'
set -g @logging_revamped_save_key 'M-p'
set -g @logging_revamped_screenshot_key 'M-P'
set -g @logging_revamped_label_key 'M-n'
set -g @logging_revamped_window_key 'M-w'
set -g @logging_revamped_clear_key 'M-c'
set -g @logging_revamped_tail_key 'M-t'
set -g @logging_revamped_search_key 'M-f'
```

<a id="how-it-works"></a>

## 運作原理

tmux 載入插件時，[`logging-revamped.tmux`](logging-revamped.tmux) 會執行一次。它將每個已設定的按鍵綁定到帶有 [`src/logging.sh`](src/logging.sh) 和動作名稱的 `run-shell`，所以在按下按鍵之前甚麼都不會執行。

它亦會將 `status-left` 和 `status-right` 中的 `#{logging_status}` 換成由兩個狀態選項組成的 `#{?pane_pipe,on,off}` 格式。這個格式由 tmux 自行繪製，所以指示器不會在每次重繪時啟動程序。請在插件載入前設定狀態選項，或在修改後重新載入設定。

即時記錄就是在 umask 077 下執行 `cat >>` 寫入檔案的 `pipe-pane`。儲存捲動緩衝區和畫面使用 `capture-pane`，並去除每行末尾的空白。標籤和搜尋提示透過 `%%%` 將輸入的文字交給插件選項，所以回覆中的引號和 `#()` 既不會進入 shell，亦不會進入格式。

檔案命名、路徑展開和清理對象的選擇都是 [`src/lib/logging/logging.sh`](src/lib/logging/logging.sh) 中的純函數。診斷報告位於 [`src/lib/logging/doctor.sh`](src/lib/logging/doctor.sh)。

<a id="development"></a>

## 開發

| 指令 | 作用 |
|:-----|:-----|
| `make test` | 執行 bats 測試套件 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 量度行覆蓋率，低於 95% 時失敗 |

變更紀錄見 [CHANGELOG.md](CHANGELOG.md)。

<a id="license"></a>

## 授權

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的成員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單確保逐位元組一致。這些成員可以一併安裝：任何成員都不會佔用其他成員使用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。這項責任寫在約定之中，而不是依靠記憶，`family/bin/sweep` 負責執行。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的任何衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
