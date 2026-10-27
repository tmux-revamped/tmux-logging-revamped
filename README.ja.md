<div align="center">

# tmux-logging-revamped

<strong>任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します。</strong>

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.1-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">機能</a> |
  <a href="#installation">インストール</a> |
  <a href="#usage">使い方</a> |
  <a href="#configuration">設定</a> |
  <a href="#key-bindings">キーバインド</a> |
  <a href="#how-it-works">仕組み</a>
</p>

</div>

メニューの操作 **12** 個、オプション **19** 個、既定で割り当てるキーは **1** つ、tmux **3.2** 以降に対応します。

---

<a id="what-it-does"></a>

## 機能

このプラグインは tmux のペインを 3 つの方法でファイルに書き出します。出力に合わせて増えていくライブのログ、スクロールバック全体の一括保存、表示中の画面の保存です。保存したファイルの追跡、検索、コピー、圧縮、削除もできます。

| 操作 | 内容 |
|:-----|:-----|
| ライブログの切り替え | `pipe-pane` によるアクティブなペインからファイルへの書き出しを開始または停止します |
| スクロールバックの保存 | ペインの履歴全体を `.history` ファイルに書き出します |
| 画面の保存 | 表示中の画面を `.screen` ファイルに書き出します |
| ラベル付きの保存 | ラベルを入力させてファイル名に加え、スクロールバックを保存します |
| ウィンドウ全体のログ | 現在のウィンドウのすべてのペインでライブログを開始します |
| 履歴の消去 | アクティブなペインのスクロールバックを消去します |
| ライブの追跡 | アクティブなペインのライブログをポップアップ内の `tail -f` で追います |
| ログの検索 | ログのディレクトリを grep し、fzf で一致を選ぶと、その行をページャーで開きます |
| 最新ログのコピー | 圧縮されていない最新のログを tmux のバッファと端末のクリップボードに読み込みます |
| ログの圧縮 | どのペインも書き込んでいないログすべてに `gzip` を実行します |
| 古いログの削除 | 保持期間のオプションに従い、日数または件数でログを削除します |
| 診断 | プラットフォーム、ログのパスと書き込み可否、モードのオプション、見つかったツールを表示します |

ファイル名は、セッション、ウィンドウ、ペイン、`YYYYmmdd-HHMMSS` 形式のタイムスタンプ、種類から作られます。例：`tmux-main-1-0-20260622-143005.history`。各部分は英数字、`.`、`_`、`-` だけに変換されるため、`feature/login` という名前のセッションでもログのディレクトリの外に出ません。

<a id="requirements"></a>

## 動作要件

| 要件 | バージョン |
|:-----|:-----------|
| tmux | 3.2 以降 |
| bash | 3.2 以降 |
| fzf | 任意のバージョン、検索でのみ使用 |
| gzip | 任意のバージョン、圧縮でのみ使用 |
| less | 任意のバージョン、検索の既定のページャー |

Linux と macOS で、BSD、GNU、uutils のいずれの coreutils でも動作します。ライブの追跡、検索、診断は `display-popup` で開き、コピーは `load-buffer -w` を使います。どちらも tmux 3.2 が必要です。

<a id="installation"></a>

## インストール

[TPM](https://github.com/tmux-plugins/tpm) を使う場合は、`~/.tmux.conf` にプラグインを追加して `prefix + I` を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

手動でインストールする場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

<a id="usage"></a>

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

削除はメニューで「Prune old logs」を選んだときだけ実行されます。

<a id="configuration"></a>

## 設定

### 動作

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

### キー

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

### 内部状態

以下のオプションはプラグイン自身が書き込みます。設定しないでください。

| オプション | 保持する内容 |
|:-----------|:-------------|
| `@logging_revamped_file_<pane>` | ライブログを記録中のペインが書き込むファイル。キーはペイン ID で、英数字以外の文字は `_` に置き換えます。例：`%3` は `_3` |
| `@logging_revamped_search_pattern` | 検索のプロンプトから選択用のポップアップに渡す検索パターン |
| `@logging_revamped_prompt` | ラベルまたは検索のプロンプトに入力した文字列。1 回読み取った後に削除します |
| `@logging_status` | 現在のステータスの文字列。`src/logging.sh status` を実行したときだけ書き込まれ、ステータスラインはこれを読みません |

<a id="key-bindings"></a>

## キーバインド

| キー | 操作 | 既定 |
|:-----|:-----|:-----|
| `prefix + M-l` | ログのメニュー | 割り当て済み |
| `@logging_revamped_<action>_key` | キーの表にある操作 | 未割り当て |

バージョン 2.0.0 でメニューは `M-m` から `M-l` に移り、ほかのキーはすべて割り当てが解除されました。以前の配置に戻すには次のように設定します。

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

## 仕組み

tmux がプラグインを読み込むと、[`logging-revamped.tmux`](logging-revamped.tmux) が 1 回実行されます。設定された各キーを、[`src/logging.sh`](src/logging.sh) と操作名を渡す `run-shell` に割り当てるため、キーを押すまで何も実行されません。

また、`status-left` と `status-right` の `#{logging_status}` を、2 つのステータスのオプションから作った `#{?pane_pipe,on,off}` 形式に置き換えます。この形式は tmux 自身が描画するため、再描画のたびにプロセスを起動することはありません。ステータスのオプションはプラグインの読み込み前に設定するか、変更後に設定を再読み込みしてください。

ライブログは、umask 077 のもとでファイルに `cat >>` を実行する `pipe-pane` です。スクロールバックと画面の保存は `capture-pane` を使い、各行の末尾の空白を取り除きます。ラベルと検索のプロンプトは入力した文字列を `%%%` 経由でプラグインのオプションに渡すため、入力に含まれる引用符や `#()` がシェルや tmux の形式に届くことはありません。

ファイル名の生成、パスの展開、削除対象の選択は [`src/lib/logging/logging.sh`](src/lib/logging/logging.sh) の純粋な関数です。診断の出力は [`src/lib/logging/doctor.sh`](src/lib/logging/doctor.sh) にあります。

<a id="development"></a>

## 開発

| コマンド | 内容 |
|:---------|:-----|
| `make test` | bats のテストスイートを実行します |
| `make lint` | すべてのシェルファイルに shellcheck を実行します |
| `make coverage` | Linux で kcov を使って行カバレッジを測定し、95% 未満なら失敗します |

変更点は [CHANGELOG.md](CHANGELOG.md) にあります。

<a id="license"></a>

## ライセンス

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
