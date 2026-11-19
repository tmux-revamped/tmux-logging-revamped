<div align="center">

# tmux-logging-revamped

<strong>将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-logging-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-logging-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-logging-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-logging-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-logging-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="logging-revamped 从菜单开始实时日志，在弹出窗口中跟随它，并按标签保存回滚内容" width="800">
</p>

```console
$ logging-revamped save before-deploy
$ ls ~/.tmux/logs
tmux-main-0-0-20261117-092106-before-deploy.history
```

插件以三种方式把 tmux 窗格写入文件：随输出不断增长的实时日志、一次性保存的完整回滚缓冲区，以及当前可见的屏幕。它还能跟踪、搜索、复制、压缩和清理这些文件。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本：弹出窗口、窗格选项和提示中的 `%%%` 都需要它 |
| fzf | 可选 | 从搜索结果中选择一项 |
| gzip | 可选 | 用于 `compress` |
| 分页器 | 可选 | 打开搜索结果，默认是 `less` |
| gum | 可选 | `logging-revamped` 的菜单、表格和颜色；没有它，所有命令都输出纯文本 |

### 安装

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

然后按 `prefix + I`。不用 TPM 时，克隆仓库，并在 `~/.tmux.conf` 中运行它的入口文件：

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

在克隆的目录中运行 `make install`，还会把 `logging-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-logging-revamped/bin/logging-revamped doctor
```

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

清理不会自动执行：在菜单中选择 Prune old logs，或运行 `logging-revamped prune`。

| 命令 | 作用 |
|:--------|:-------------|
| `logging-revamped apply` | 立即绑定按键和状态指示；插件加载时入口点会运行它 |
| `logging-revamped list` | 打印 `apply` 会发送的每条命令，不做任何修改；`--json` 输出一个对象 |
| `logging-revamped toggle` | 用 `pipe-pane` 开始或停止把当前窗格写入文件 |
| `logging-revamped save [LABEL]` | 把整个窗格历史写入 `.history` 文件 |
| `logging-revamped screenshot [LABEL]` | 把可见屏幕写入 `.screen` 文件 |
| `logging-revamped label` | 询问一个标签，加入文件名，然后保存回滚缓冲区 |
| `logging-revamped window` | 为当前窗口的每个窗格开始实时日志 |
| `logging-revamped clear` | 清除当前窗格的回滚缓冲区 |
| `logging-revamped tail` | 在弹出窗口中用 `tail -f` 跟踪当前窗格的实时日志 |
| `logging-revamped search [PATTERN]` | 在日志目录中 grep，在 fzf 中选择匹配项，并在分页器中打开到对应行 |
| `logging-revamped copy` | 把最新的未压缩日志载入 tmux 缓冲区和终端剪贴板 |
| `logging-revamped compress` | 对所有没有窗格仍在写入的日志运行 `gzip` |
| `logging-revamped prune` | 按保留选项的设置，按时间或数量删除日志 |
| `logging-revamped status` | 打印此窗格的指示文字 |
| `logging-revamped doctor` | 每个依赖一行，包括日志文件夹、gzip、fzf 和保持不动的按键 |
| `logging-revamped version` | 版本，然后是 tmux 版本 |
| `logging-revamped help` | 帮助页；`man logging-revamped` 记录相同的命令和设置 |
| `logging-revamped` | 在终端上显示菜单 |

文件名由会话、窗口和窗格、`YYYYmmdd-HHMMSS` 格式的时间戳以及类型组成，例如 `tmux-main-1-0-20260622-143005.history`。每一部分都只保留字母、数字、`.`、`_` 和 `-`，所以名为 `feature/login` 的会话也不会跑出日志目录。

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

每个选项也可以用带连字符的命令选项（例如 `--path ~/logs`）和环境变量（例如 `LOGGING_REVAMPED_PATH`）设置；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。`doctor` 会指出值无法识别的设置。传给 `apply` 的选项会随每个绑定一起生效。

插件自己写入三个选项：窗格选项 `@logging_revamped_file` 是正在记录的窗格写入的文件，全局的 `@logging_revamped_prompt` 和 `@logging_revamped_search_pattern` 把输入的回复交给工具。

<a id="工作原理"></a>

## 工作原理

[`logging-revamped.tmux`](logging-revamped.tmux) 在 tmux 加载插件时运行一次 `bin/logging-revamped apply`。它用一次 tmux 调用，把每个已配置的按键绑定到带有工具和动作名的 `run-shell`，把菜单键绑定到菜单本身，所以在你按键之前什么都不会运行。

它还会把 `status-left` 和 `status-right` 中的 `#{logging_status}` 替换为由两个状态选项构成的 `#{?pane_pipe,on,off}` 格式。这个格式由 tmux 自己绘制，所以指示器不会在每次重绘时启动进程。请在插件加载前设置状态选项，或在修改后重新加载配置。

实时日志就是在 umask 077 下运行 `cat >>` 写入文件的 `pipe-pane`。保存回滚缓冲区和屏幕使用 `capture-pane`，并去掉每行末尾的空白。标签和搜索提示通过 `%%%` 把输入的文字交给插件选项，所以回复中的引号和 `#()` 既不会进入 shell，也不会进入格式。

<a id="界面"></a>

## 界面

<details>
<summary>所有界面，在真实的 tmux 中用 <code>make screens</code> 录制，每个按键显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/logging-menu.png" alt="logging-revamped：prefix M-l 打开日志菜单"><br><sub><code>prefix M-l</code> 打开日志菜单，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/live.png" alt="logging-revamped：实时日志开始，状态栏随之提示"><br><sub>实时日志开始，状态栏随之提示，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/tail.png" alt="logging-revamped：prefix M-t 在弹出窗口中跟随实时日志"><br><sub><code>prefix M-t</code> 在弹出窗口中跟随实时日志，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/saved.png" alt="logging-revamped：save 按标签保存回滚内容"><br><sub><code>save</code> 按标签保存回滚内容，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="logging-revamped：菜单"><br><sub>菜单，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="logging-revamped：doctor"><br><sub><code>doctor</code>，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/label.png" alt="logging-revamped：标签键询问标签"><br><sub>标签键询问标签，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/search.png" alt="logging-revamped：搜索键列出所有匹配"><br><sub>搜索键列出所有匹配，来自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/match.png" alt="logging-revamped：选中的匹配在分页器中定位到所在行"><br><sub>选中的匹配在分页器中定位到所在行，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/window.png" alt="logging-revamped：窗口键记录每个窗格"><br><sub>窗口键记录每个窗格，来自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/screenshot.png" alt="logging-revamped：从菜单保存屏幕"><br><sub>从菜单保存屏幕，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clear.png" alt="logging-revamped：从菜单清除历史"><br><sub>从菜单清除历史，来自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="logging-revamped：从菜单复制最新日志"><br><sub>从菜单复制最新日志，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/compress.png" alt="logging-revamped：从菜单压缩日志"><br><sub>从菜单压缩日志，来自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/prune.png" alt="logging-revamped：从菜单清理旧日志"><br><sub>从菜单清理旧日志，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="logging-revamped：list 打印每个绑定"><br><sub><code>list</code> 打印每个绑定，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="logging-revamped：status"><br><sub><code>status</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="logging-revamped：没有 gum 的菜单"><br><sub>没有 gum 的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="logging-revamped：从菜单运行 doctor"><br><sub>从菜单运行 <code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="logging-revamped：版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="logging-revamped：未知命令"><br><sub>未知命令，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="logging-revamped：六种主题下的标题"><br><sub>六种主题下的标题，来自 <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="logging-revamped：帮助页"><br><sub>帮助页，来自 <code>help.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="logging-revamped：来自 LOGGING_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>LOGGING_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
</tr>
</table>

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **本插件**，将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
