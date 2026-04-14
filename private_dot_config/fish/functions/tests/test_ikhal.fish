#!/usr/bin/env fish
# ikhal.fish のテストスイート
# fishtape が未インストールのため、シンプルなシェルテストで実装
#
# 実行方法: fish ~/.config/fish/functions/tests/test_ikhal.fish

set -g pass_count 0
set -g fail_count 0
set -g test_dir (mktemp -d)
set -g calls_log "$test_dir/calls.log"
set -g ikhal_func /home/yoshimi/.config/fish/functions/ikhal.fish

# ------------------------------------------------------------------------------
# テストユーティリティ
# ------------------------------------------------------------------------------

function assert_equal --description "2つの値が等しいか検証する"
    set -l description $argv[1]
    set -l expected $argv[2]
    set -l actual $argv[3]

    if test "$expected" = "$actual"
        set -g pass_count (math $pass_count + 1)
        echo "  [PASS] $description"
    else
        set -g fail_count (math $fail_count + 1)
        echo "  [FAIL] $description"
        echo "         期待値: '$expected'"
        echo "         実際値: '$actual'"
    end
end

function assert_contains --description "文字列が指定パターンを含むか検証する"
    set -l description $argv[1]
    set -l pattern $argv[2]
    set -l actual $argv[3]

    if string match -q "*$pattern*" -- $actual
        set -g pass_count (math $pass_count + 1)
        echo "  [PASS] $description"
    else
        set -g fail_count (math $fail_count + 1)
        echo "  [FAIL] $description"
        echo "         パターン: '$pattern'"
        echo "         実際値:   '$actual'"
    end
end

function assert_file_contains --description "ファイルが指定パターンを含むか検証する"
    set -l description $argv[1]
    set -l pattern $argv[2]
    set -l filepath $argv[3]

    # -- を挟むことで、パターンが "-v" のような場合に grep のオプションと誤解されるのを防ぐ
    if grep -qF -- "$pattern" "$filepath" 2>/dev/null
        set -g pass_count (math $pass_count + 1)
        echo "  [PASS] $description"
    else
        set -g fail_count (math $fail_count + 1)
        echo "  [FAIL] $description"
        echo "         パターン '$pattern' がファイル '$filepath' に見つかりません"
    end
end

function count_file_pattern --description "ファイル内のパターン一致行数を整数で返す"
    set -l pattern $argv[1]
    set -l filepath $argv[2]
    # grep -c は一致がなくても 0 を返す (exit code 1 でも数は出力される)
    # 失敗時は明示的に 0 を返す
    # -- を挟んで、パターンが "-" で始まる場合の誤解釈を防ぐ
    set -l n (grep -cF -- "$pattern" "$filepath" 2>/dev/null)
    or set n 0
    # "0\n0" のような複数行出力を防ぐため最初の行だけ取る
    echo $n | head -1
end

function setup_mocks --description "モックコマンドを一時ディレクトリに作成する (成功パターン)"
    # モック: vdirsyncer (終了コード 0)
    set -l log $calls_log
    printf '#!/bin/sh\nprintf "vdirsyncer: %%s\\n" "$*" >> "%s"\nexit 0\n' "$log" \
        > "$test_dir/vdirsyncer"
    chmod +x "$test_dir/vdirsyncer"

    # モック: ikhal (実際の ikhal の代わり; 終了コード 0)
    printf '#!/bin/sh\nprintf "ikhal: %%s\\n" "$*" >> "%s"\nexit 0\n' "$log" \
        > "$test_dir/ikhal"
    chmod +x "$test_dir/ikhal"
end

function setup_failing_vdirsyncer --description "失敗するvdirsyncerモックを作成する"
    set -l log $calls_log
    printf '#!/bin/sh\nprintf "vdirsyncer: %%s (FAIL)\\n" "$*" >> "%s"\nexit 1\n' "$log" \
        > "$test_dir/vdirsyncer"
    chmod +x "$test_dir/vdirsyncer"
end

function reset_log --description "呼び出しログをリセットする"
    printf '' > "$calls_log"
end

# fish サブシェルを --no-config で起動し、ikhal.fish だけを source して実行する
# PATH の先頭にモックディレクトリを追加することで command ikhal も差し替える
function run_wrapper --description "テスト用環境でラッパー関数を実行する"
    # 引数をシェル安全な形式に変換する
    # $argv をそのままリストとして fish サブシェルに渡す
    env PATH="$test_dir:$PATH" \
        IKHAL_TEST_FUNC="$ikhal_func" \
        fish --no-config -c "
            source \$IKHAL_TEST_FUNC
            ikhal $argv
        " 2>&1
end

# ------------------------------------------------------------------------------
# テストケース
# ------------------------------------------------------------------------------

echo ""
echo "=== ikhal.fish テストスイート ==="
echo ""

# --- テスト 1: 正常系 - 実行順序の検証 ---
echo "テスト 1: 正常系 - vdirsyncer → ikhal → vdirsyncer の順に呼ばれる"
setup_mocks
reset_log

run_wrapper > /dev/null 2>&1

# 行番号を抽出
set -l first_vdir_line  (grep -nF "vdirsyncer:" "$calls_log" 2>/dev/null | head -1 | cut -d: -f1)
set -l last_vdir_line   (grep -nF "vdirsyncer:" "$calls_log" 2>/dev/null | tail -1 | cut -d: -f1)
set -l ikhal_line_num   (grep -nF "ikhal:"      "$calls_log" 2>/dev/null | head -1 | cut -d: -f1)

assert_file_contains "事前 sync が実行される" "vdirsyncer: sync google_calendar" "$calls_log"
assert_file_contains "ikhal が実行される" "ikhal:" "$calls_log"

if test -n "$first_vdir_line" -a -n "$ikhal_line_num"; and test "$first_vdir_line" -lt "$ikhal_line_num"
    set -g pass_count (math $pass_count + 1)
    echo "  [PASS] 事前 sync が ikhal より先に実行される"
else
    set -g fail_count (math $fail_count + 1)
    echo "  [FAIL] 事前 sync が ikhal より先に実行される"
    echo "         vdirsyncer 行: '$first_vdir_line' / ikhal 行: '$ikhal_line_num'"
end

if test -n "$ikhal_line_num" -a -n "$last_vdir_line"; and test "$ikhal_line_num" -lt "$last_vdir_line"
    set -g pass_count (math $pass_count + 1)
    echo "  [PASS] 事後 sync が ikhal より後に実行される"
else
    set -g fail_count (math $fail_count + 1)
    echo "  [FAIL] 事後 sync が ikhal より後に実行される"
    echo "         ikhal 行: '$ikhal_line_num' / 最後の vdirsyncer 行: '$last_vdir_line'"
end

echo ""

# --- テスト 2: 引数の受け渡し ---
echo "テスト 2: ikhal に引数が正しく渡される"
setup_mocks
reset_log

run_wrapper -v --some-option > /dev/null 2>&1

assert_file_contains "引数 -v が渡される" "-v" "$calls_log"
assert_file_contains "引数 --some-option が渡される" "--some-option" "$calls_log"

echo ""

# --- テスト 3: vdirsyncer が失敗しても ikhal は実行される ---
echo "テスト 3: 事前 vdirsyncer が失敗しても ikhal が実行される"
setup_mocks
setup_failing_vdirsyncer
reset_log

run_wrapper > /dev/null 2>&1

assert_file_contains "vdirsyncer が失敗した記録がある" "FAIL" "$calls_log"
assert_file_contains "それでも ikhal が実行される" "ikhal:" "$calls_log"

echo ""

# --- テスト 4: 事後 sync は必ず実行される ---
echo "テスト 4: 事後 vdirsyncer は事前 sync が失敗しても実行される"
setup_mocks
setup_failing_vdirsyncer
reset_log

run_wrapper > /dev/null 2>&1

set -l vdir_count (count_file_pattern "vdirsyncer:" "$calls_log")
if test "$vdir_count" -ge 2
    set -g pass_count (math $pass_count + 1)
    echo "  [PASS] 事後 sync も実行される (vdirsyncer が2回呼ばれた)"
else
    set -g fail_count (math $fail_count + 1)
    echo "  [FAIL] 事後 sync も実行される"
    echo "         vdirsyncer 呼び出し回数: $vdir_count"
end

echo ""

# --- テスト 5: ユーザーへのメッセージ表示 ---
echo "テスト 5: ユーザーに進捗メッセージが表示される"
setup_mocks
reset_log

set -l output (run_wrapper 2>&1)

assert_contains "進捗メッセージが表示される" "同期中" "$output"

echo ""

# --- テスト 6: 引数なしでも動作する ---
echo "テスト 6: 引数なしでも正常に動作する"
setup_mocks
reset_log

run_wrapper > /dev/null 2>&1
set -l exit_code $status

assert_equal "引数なしで正常終了する" "0" "$exit_code"

echo ""

# --- テスト 7: google_calendar を指定して sync が呼ばれる ---
echo "テスト 7: vdirsyncer sync google_calendar が正確に呼ばれる"
setup_mocks
reset_log

run_wrapper > /dev/null 2>&1

assert_file_contains "sync コマンドに google_calendar が渡される" \
    "sync google_calendar" "$calls_log"

echo ""

# --- テスト 8: command ikhal で再帰しない (実装の確認) ---
echo "テスト 8: 実装に 'command ikhal' が含まれ再帰を回避している"
assert_file_contains "'command ikhal' が実装に含まれる" "command ikhal" \
    "$ikhal_func"

echo ""

# --- テスト 9: vdirsyncer が2回呼ばれる (正常系) ---
echo "テスト 9: 正常系で vdirsyncer が2回 (事前・事後) 呼ばれる"
setup_mocks
reset_log

run_wrapper > /dev/null 2>&1

set -l count (count_file_pattern "vdirsyncer:" "$calls_log")
assert_equal "vdirsyncer が2回呼ばれる" "2" "$count"

echo ""

# ------------------------------------------------------------------------------
# 結果サマリ
# ------------------------------------------------------------------------------
set -l total (math $pass_count + $fail_count)
echo "=================================="
echo "結果: $pass_count / $total テストパス"
if test $fail_count -gt 0
    echo "失敗: $fail_count テスト"
    echo "状態: RED (実装が必要)"
else
    echo "状態: GREEN"
end
echo "=================================="

# クリーンアップ
rm -rf "$test_dir"

if test $fail_count -gt 0
    exit 1
else
    exit 0
end
