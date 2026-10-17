<div align="center">

# tmux-logging-revamped

<strong>将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> &nbsp;|&nbsp;
  <a href="#installation">安装</a> &nbsp;|&nbsp;
  <a href="#usage">用法</a> &nbsp;|&nbsp;
  <a href="#configuration">配置</a> &nbsp;|&nbsp;
  <a href="#key-bindings">按键绑定</a> &nbsp;|&nbsp;
  <a href="#how-it-works">工作原理</a>
</p>

</div>

**12** 个菜单操作，**19** 个选项，默认只绑定 **1** 个按键，支持 tmux **3.2** 及以上版本。

---

<a id="what-it-does"></a>

## 功能

插件以三种方式把 tmux 窗格写入文件：随输出不断增长的实时日志、一次性保存的完整回滚缓冲区，以及当前可见的屏幕。它还能跟踪、搜索、复制、压缩和清理这些文件。

| 操作 | 作用 |
|:-----|:-----|
| 切换实时日志 | 用 `pipe-pane` 开始或停止把当前窗格写入文件 |
| 保存回滚缓冲区 | 把整个窗格历史写入 `.history` 文件 |
| 保存屏幕 | 把可见屏幕写入 `.screen` 文件 |
| 带标签保存 | 询问一个标签，加入文件名，然后保存回滚缓冲区 |
| 记录整个窗口 | 为当前窗口的每个窗格开始实时日志 |
| 清除历史 | 清除当前窗格的回滚缓冲区 |
| 实时跟踪 | 在弹出窗口中用 `tail -f` 跟踪当前窗格的实时日志 |
| 搜索日志 | 在日志目录中 grep，在 fzf 中选择匹配项，并在分页器中打开到对应行 |
| 复制最新日志 | 把最新的未压缩日志载入 tmux 缓冲区和终端剪贴板 |
| 压缩日志 | 对所有没有窗格仍在写入的日志运行 `gzip` |
| 清理旧日志 | 按保留选项的设置，按时间或数量删除日志 |
| 诊断 | 显示平台、日志路径及其是否可写、模式选项以及找到了哪些工具 |

文件名由会话、窗口和窗格、`YYYYmmdd-HHMMSS` 格式的时间戳以及类型组成，例如 `tmux-main-1-0-20260622-143005.history`。每一部分都只保留字母、数字、`.`、`_` 和 `-`，所以名为 `feature/login` 的会话也不会跑出日志目录。

<a id="requirements"></a>

## 环境要求

| 依赖 | 版本 |
|:-----|:-----|
| tmux | 3.2 及以上 |
| bash | 3.2 及以上 |
| fzf | 任意版本，仅搜索需要 |
| gzip | 任意版本，仅压缩需要 |
| less | 任意版本，搜索的默认分页器 |

可在 Linux 和 macOS 上运行，支持 BSD、GNU 或 uutils coreutils。实时跟踪、搜索和诊断在 `display-popup` 中打开，复制使用 `load-buffer -w`，两者都需要 tmux 3.2。

<a id="installation"></a>

## 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

手动安装时，克隆仓库，并在 `~/.tmux.conf` 中运行入口脚本：

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

<a id="usage"></a>

## 用法

按 `prefix + M-l` 打开日志菜单，其中列出全部 12 个操作。

为最常用的操作分配专用按键，并在当前窗格正在记录时在状态栏显示标记：

```tmux
set -g @logging_revamped_toggle_key 'P'
set -g @logging_revamped_save_key 'M-p'
set -g @logging_revamped_tail_key 'M-t'

set -g @logging_revamped_status_on 'REC'
set -g status-right '#{logging_status} %H:%M'
```

日志最多保留两周，并在保存回滚缓冲区时去掉提示符行：

```tmux
set -g @logging_revamped_path '~/logs/tmux'
set -g @logging_revamped_retain_days '14'
set -g @logging_revamped_output_only '1'
```

只有在菜单中选择 Prune old logs 时才会执行清理。

<a id="configuration"></a>

## 配置

### 行为

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@logging_revamped_path` | `~/.tmux/logs` | 存放所有文件的目录；首次需要时以 700 权限创建 |
| `@logging_revamped_color` | `0` | 设为 `1` 时，在保存的回滚缓冲区和屏幕中保留 ANSI 颜色序列 |
| `@logging_revamped_rolling` | `0` | 设为 `1` 时，实时日志追加到每个会话一个的 `tmux-<session>-session.log` |
| `@logging_revamped_output_only` | `0` | 设为 `1` 时，从保存的回滚缓冲区和屏幕中去掉匹配提示符模式的行 |
| `@logging_revamped_prompt_pattern` | `^[[:space:]]*[#$%>] ` | 仅输出模式要去掉的行所用的扩展正则表达式 |
| `@logging_revamped_retain_days` | `0` | 大于 0 时，清理会删除早于此天数的未压缩日志 |
| `@logging_revamped_retain_max` | `0` | 大于 0 时，清理只保留最新的这么多个日志 |
| `@logging_revamped_pager` | `less` | 打开搜索匹配项的分页器，以 `<pager> +<line> -- <file>` 方式调用 |
| `@logging_revamped_status_on` | `*` | 当前窗格正在记录时 `#{logging_status}` 显示的文字 |
| `@logging_revamped_status_off` | 空 | 其他情况下 `#{logging_status}` 显示的文字 |

### 按键

每个按键选项接受一个 tmux 按键名。值为空或 `off` 时不绑定任何按键。

| 选项 | 默认值 | 操作 |
|:-----|:-------|:-----|
| `@logging_revamped_menu_key` | `M-l` | 日志菜单 |
| `@logging_revamped_toggle_key` | 空 | 切换实时日志 |
| `@logging_revamped_save_key` | 空 | 保存回滚缓冲区 |
| `@logging_revamped_screenshot_key` | 空 | 保存屏幕 |
| `@logging_revamped_label_key` | 空 | 带标签保存 |
| `@logging_revamped_window_key` | 空 | 记录整个窗口 |
| `@logging_revamped_clear_key` | 空 | 清除历史 |
| `@logging_revamped_tail_key` | 空 | 实时跟踪 |
| `@logging_revamped_search_key` | 空 | 搜索日志 |

复制、压缩、清理和诊断没有按键选项，从菜单中使用。

### 内部状态

以下选项由插件自己写入，请勿设置。

| 选项 | 保存内容 |
|:-----|:---------|
| `@logging_revamped_file_<pane>` | 正在实时记录的窗格写入的文件，以窗格 ID 为键，除字母和数字外的字符都替换为 `_`，例如 `%3` 对应 `_3` |
| `@logging_revamped_search_pattern` | 从搜索提示传给选择器弹出窗口的搜索模式 |
| `@logging_revamped_prompt` | 在标签或搜索提示中输入的文字，读取一次后删除 |
| `@logging_status` | 当前的状态文字，只在运行 `src/logging.sh status` 时写入；状态栏不读取它 |

<a id="key-bindings"></a>

## 按键绑定

| 按键 | 操作 | 默认 |
|:-----|:-----|:-----|
| `prefix + M-l` | 日志菜单 | 已绑定 |
| `@logging_revamped_<action>_key` | 按键表中对应的操作 | 未绑定 |

2.0.0 版把菜单从 `M-m` 移到 `M-l`，并取消了其他所有按键的绑定。要恢复旧的布局：

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

## 工作原理

tmux 加载插件时，[`logging-revamped.tmux`](logging-revamped.tmux) 运行一次。它把每个已配置的按键绑定到带有 [`src/logging.sh`](src/logging.sh) 和操作名的 `run-shell`，所以在按下按键之前什么都不会运行。

它还会把 `status-left` 和 `status-right` 中的 `#{logging_status}` 替换为由两个状态选项构成的 `#{?pane_pipe,on,off}` 格式。这个格式由 tmux 自己绘制，所以指示器不会在每次重绘时启动进程。请在插件加载前设置状态选项，或在修改后重新加载配置。

实时日志就是在 umask 077 下运行 `cat >>` 写入文件的 `pipe-pane`。保存回滚缓冲区和屏幕使用 `capture-pane`，并去掉每行末尾的空白。标签和搜索提示通过 `%%%` 把输入的文字交给插件选项，所以回复中的引号和 `#()` 既不会进入 shell，也不会进入格式。

文件命名、路径展开和清理对象的选择都是 [`src/lib/logging/logging.sh`](src/lib/logging/logging.sh) 中的纯函数。诊断报告位于 [`src/lib/logging/doctor.sh`](src/lib/logging/doctor.sh)。

<a id="development"></a>

## 开发

| 命令 | 作用 |
|:-----|:-----|
| `make test` | 运行 bats 测试套件 |
| `make lint` | 对所有 shell 文件运行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 测量行覆盖率，低于 95% 时失败 |

变更记录见 [CHANGELOG.md](CHANGELOG.md)。

<a id="license"></a>

## 许可证

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保证逐字节一致。这些成员可以一起安装：任何成员都不会占用其他成员使用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。这项义务写在约定里，而不是靠记忆，`family/bin/sweep` 负责执行它。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后自动重新加载，无需按键或命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘使用情况，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 选取屏幕上的 URL、路径、哈希或其他任意词元，并在光标处输入，纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口的 fzf 选择器中切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏显示当前窗格的 Git 分支、改动和代码托管平台计数，不阻塞状态栏 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏显示当前 Kubernetes 上下文和命名空间，直接解析 kubeconfig，无需 kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **本插件**，将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的标准窗格和窗口管理按键，适配 tmux 版本，兼容 vim，全部可配置 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存所有 tmux 会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | 用于构建不阻塞的 tmux 状态栏插件的模板 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标沿 tmux 状态栏拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 把鼠标滚轮交给能自行滚动的应用，其他地方进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端启用的合理默认值，不改动你设置过的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：8 种布局，包括 BSP dwindle 和 spiral，支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 用于 tmux 状态栏的本地时钟和世界时钟，按一天中的时段着色，带倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在 tmux 状态栏显示来自 wttr.in 的天气，在后台获取，状态栏从不等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的任何冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
