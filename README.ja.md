<div align="center">

# tmux-logging-revamped

<strong>任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-logging-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-logging-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-logging-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-logging-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-logging-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="メニューからライブログを始め、ポップアップで追い、ラベルを付けてスクロールバックを保存する logging-revamped" width="800">
</p>

```console
$ logging-revamped save before-deploy
$ ls ~/.tmux/logs
tmux-main-0-0-20261117-092106-before-deploy.history
```

このプラグインは tmux のペインを 3 つの方法でファイルに書き出します。出力に合わせて増えていくライブのログ、スクロールバック全体の一括保存、表示中の画面の保存です。保存したファイルの追跡、検索、コピー、圧縮、削除もできます。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン。ポップアップ、ペインのオプション、プロンプトの `%%%` に必要です |
| fzf | 任意 | 検索結果から 1 つ選びます |
| gzip | 任意 | `compress` 用 |
| ページャー | 任意 | 検索結果を開きます。既定は `less` |
| gum | 任意 | `logging-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

### インストール

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

続けて `prefix + I` を押します。TPM を使わない場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリーポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

クローンで `make install` を実行すると、`logging-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-logging-revamped/bin/logging-revamped doctor
```

## 使い方

`prefix + M-l` を押すとログのメニューが開き、12 個の操作がすべて表示されます。

よく使う操作には専用のキーを割り当て、アクティブなペインのログを記録している間はステータスラインに印を表示します。

```tmux
set -g @logging_revamped_toggle_key 'P'
set -g @logging_revamped_save_key 'M-p'
set -g @logging_revamped_tail_key 'M-t'

set -g @logging_revamped_status_on 'REC'
set -g status-right '#{logging_status} %H:%M'
```

ログを最大 2 週間保持し、プロンプトの行を除いてスクロールバックを保存する例です。

```tmux
set -g @logging_revamped_path '~/logs/tmux'
set -g @logging_revamped_retain_days '14'
set -g @logging_revamped_output_only '1'
```

削除が自動で実行されることはありません。メニューで「Prune old logs」を選ぶか、`logging-revamped prune` を実行します。

| コマンド | 動作 |
|:--------|:-------------|
| `logging-revamped apply` | キーとステータス表示を今すぐ割り当てます。プラグインの読み込み時にエントリーポイントが実行します |
| `logging-revamped list` | `apply` が送るコマンドをすべて表示し、何も変更しません。`--json` で 1 つのオブジェクトを出力します |
| `logging-revamped toggle` | `pipe-pane` によるアクティブなペインからファイルへの書き出しを開始または停止します |
| `logging-revamped save [LABEL]` | ペインの履歴全体を `.history` ファイルに書き出します |
| `logging-revamped screenshot [LABEL]` | 表示中の画面を `.screen` ファイルに書き出します |
| `logging-revamped label` | ラベルを入力させてファイル名に加え、スクロールバックを保存します |
| `logging-revamped window` | 現在のウィンドウのすべてのペインでライブログを開始します |
| `logging-revamped clear` | アクティブなペインのスクロールバックを消去します |
| `logging-revamped tail` | アクティブなペインのライブログをポップアップ内の `tail -f` で追います |
| `logging-revamped search [PATTERN]` | ログのディレクトリを grep し、fzf で一致を選ぶと、その行をページャーで開きます |
| `logging-revamped copy` | 圧縮されていない最新のログを tmux のバッファと端末のクリップボードに読み込みます |
| `logging-revamped compress` | どのペインも書き込んでいないログすべてに `gzip` を実行します |
| `logging-revamped prune` | 保持期間のオプションに従い、日数または件数でログを削除します |
| `logging-revamped status` | このペインの表示文字を出力します |
| `logging-revamped doctor` | 依存関係ごとに 1 行。ログのフォルダー、gzip、fzf、触れなかったキーも含みます |
| `logging-revamped version` | バージョンと tmux のバージョン |
| `logging-revamped help` | ヘルプ。`man logging-revamped` にも同じコマンドと設定があります |
| `logging-revamped` | 端末ではメニュー |

ファイル名は、セッション、ウィンドウ、ペイン、`YYYYmmdd-HHMMSS` 形式のタイムスタンプ、種類から作られます。例：`tmux-main-1-0-20260622-143005.history`。各部分は英数字、`.`、`_`、`-` だけに変換されるため、`feature/login` という名前のセッションでもログのディレクトリの外に出ません。

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@logging_revamped_path` | `~/.tmux/logs` | すべてのファイルを置くディレクトリ。最初に必要になったときにモード 700 で作成します |
| `@logging_revamped_color` | `0` | `1` にすると、保存したスクロールバックと画面に ANSI の色のシーケンスを残します |
| `@logging_revamped_rolling` | `0` | `1` にすると、ライブログはセッションごとに 1 つの `tmux-<session>-session.log` に追記されます |
| `@logging_revamped_output_only` | `0` | `1` にすると、保存したスクロールバックと画面からプロンプトのパターンに一致する行を除きます |
| `@logging_revamped_prompt_pattern` | `^[[:space:]]*[#$%>] ` | 出力のみモードで除く行の拡張正規表現 |
| `@logging_revamped_retain_days` | `0` | 0 より大きい場合、削除操作はこの日数より古い未圧縮のログを削除します |
| `@logging_revamped_retain_max` | `0` | 0 より大きい場合、削除操作は新しい順にこの件数だけログを残します |
| `@logging_revamped_pager` | `less` | 検索の一致を開くページャー。`<pager> +<line> -- <file>` の形で呼び出します |
| `@logging_revamped_status_on` | `*` | アクティブなペインのログを記録している間に `#{logging_status}` が表示する文字列 |
| `@logging_revamped_status_off` | 空 | それ以外のときに `#{logging_status}` が表示する文字列 |

各キーのオプションには tmux のキー名を指定します。空の値または `off` では何も割り当てません。

| オプション | 既定値 | 操作 |
|:-----------|:-------|:-----|
| `@logging_revamped_menu_key` | `M-l` | ログのメニュー |
| `@logging_revamped_toggle_key` | 空 | ライブログの切り替え |
| `@logging_revamped_save_key` | 空 | スクロールバックの保存 |
| `@logging_revamped_screenshot_key` | 空 | 画面の保存 |
| `@logging_revamped_label_key` | 空 | ラベル付きの保存 |
| `@logging_revamped_window_key` | 空 | ウィンドウ全体のログ |
| `@logging_revamped_clear_key` | 空 | 履歴の消去 |
| `@logging_revamped_tail_key` | 空 | ライブの追跡 |
| `@logging_revamped_search_key` | 空 | ログの検索 |

コピー、圧縮、削除、診断にはキーのオプションがなく、メニューから使います。

どのオプションも、ダッシュ区切りのコマンドオプション（例 `--path ~/logs`）と環境変数（例 `LOGGING_REVAMPED_PATH`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`apply` に渡したものは、すべての割り当てに引き継がれます。

プラグイン自身が書き込むオプションは 3 つです。ペインのオプション `@logging_revamped_file` は記録中のペインが書き込むファイルで、グローバルの `@logging_revamped_prompt` と `@logging_revamped_search_pattern` は入力された返答をツールに渡します。

<a id="仕組み"></a>

## 仕組み

[`logging-revamped.tmux`](logging-revamped.tmux) は、tmux がプラグインを読み込むときに `bin/logging-revamped apply` を一度実行します。設定した各キーを、ツールとアクション名を付けた `run-shell` に、メニューのキーをメニューそのものに、1 回の tmux 呼び出しで割り当てます。キーを押すまで何も実行されません。

また、`status-left` と `status-right` の `#{logging_status}` を、2 つのステータスのオプションから作った `#{?pane_pipe,on,off}` 形式に置き換えます。この形式は tmux 自身が描画するため、再描画のたびにプロセスを起動することはありません。ステータスのオプションはプラグインの読み込み前に設定するか、変更後に設定を再読み込みしてください。

ライブログは、umask 077 のもとでファイルに `cat >>` を実行する `pipe-pane` です。スクロールバックと画面の保存は `capture-pane` を使い、各行の末尾の空白を取り除きます。ラベルと検索のプロンプトは入力した文字列を `%%%` 経由でプラグインのオプションに渡すため、入力に含まれる引用符や `#()` がシェルや tmux の形式に届くことはありません。

<a id="画面"></a>

## 画面

<details>
<summary>すべての画面。本物の tmux の中で <code>make screens</code> で録画し、押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/logging-menu.png" alt="logging-revamped: prefix M-l でログのメニューを開く"><br><sub><code>prefix M-l</code> でログのメニューを開く。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/live.png" alt="logging-revamped: ライブログが始まり、ステータスラインに表示される"><br><sub>ライブログが始まり、ステータスラインに表示される。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/tail.png" alt="logging-revamped: prefix M-t でライブログをポップアップで追う"><br><sub><code>prefix M-t</code> でライブログをポップアップで追う。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/saved.png" alt="logging-revamped: save がラベル付きでスクロールバックを保存する"><br><sub><code>save</code> がラベル付きでスクロールバックを保存する。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="logging-revamped: メニュー"><br><sub>メニュー。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="logging-revamped: doctor"><br><sub><code>doctor</code>。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/label.png" alt="logging-revamped: ラベルのキーがラベルを尋ねる"><br><sub>ラベルのキーがラベルを尋ねる。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/search.png" alt="logging-revamped: 検索のキーが一致をすべて並べる"><br><sub>検索のキーが一致をすべて並べる。<code>keys.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/match.png" alt="logging-revamped: 選んだ一致がページャーでその行に開く"><br><sub>選んだ一致がページャーでその行に開く。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/window.png" alt="logging-revamped: ウィンドウのキーがすべてのペインを記録する"><br><sub>ウィンドウのキーがすべてのペインを記録する。<code>keys.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/screenshot.png" alt="logging-revamped: メニューからの画面の保存"><br><sub>メニューからの画面の保存。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/clear.png" alt="logging-revamped: メニューからの履歴の消去"><br><sub>メニューからの履歴の消去。<code>keys.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="logging-revamped: メニューからの最新ログのコピー"><br><sub>メニューからの最新ログのコピー。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/compress.png" alt="logging-revamped: メニューからのログの圧縮"><br><sub>メニューからのログの圧縮。<code>keys.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/prune.png" alt="logging-revamped: メニューからの古いログの削除"><br><sub>メニューからの古いログの削除。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="logging-revamped: list がすべての割り当てを表示する"><br><sub><code>list</code> がすべての割り当てを表示する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="logging-revamped: status"><br><sub><code>status</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="logging-revamped: gum なしのメニュー"><br><sub>gum なしのメニュー。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="logging-revamped: メニューからの doctor"><br><sub>メニューからの <code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="logging-revamped: バージョン"><br><sub>バージョン。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="logging-revamped: 不明なコマンド"><br><sub>不明なコマンド。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="logging-revamped: 6 つのテーマのヘッダー"><br><sub>6 つのテーマのヘッダー。<code>themes.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="logging-revamped: ヘルプ"><br><sub>ヘルプ。<code>help.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="logging-revamped: LOGGING_REVAMPED_ACCENT によるアクセント"><br><sub><code>LOGGING_REVAMPED_ACCENT</code> によるアクセント。<code>stills.tape</code>より</sub></td>
</tr>
</table>

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **このプラグイン**、任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
