function nbs --description "herdr workspace の label / tmux セッション名に紐づく nb ノートを開く/作成する"
    argparse p/print n/name -- $argv
    or return 1

    # タイトル: 引数 > herdr のワークスペース label > tmux のセッション名
    set -l label $argv[1]
    if test -z "$label"
        if set -q HERDR_ENV
            # ペインはワークスペース間を移動できるので，現在のペインから workspace_id を引く
            set -l ws_id (command herdr pane current 2>/dev/null | jq -r '.result.pane.workspace_id // empty')
            test -n "$ws_id"; or set ws_id $HERDR_WORKSPACE_ID
            set label (command herdr workspace get "$ws_id" 2>/dev/null | jq -r '.result.workspace.label // empty')
        else if set -q TMUX
            set label (tmux display-message -p '#S')
        else
            echo "herdr/tmux の外ではタイトルを引数で指定してください" >&2
            return 1
        end
    end

    if test -z "$label"
        echo "workspace の label を取得できませんでした (herdr workspace rename でラベルを付けてください)" >&2
        return 1
    end

    if set -q _flag_name
        echo $label
        return 0
    end

    # label とタイトルが完全一致するノートを検索
    # nb list は "[id] title" または "[id] filename · \"title\"" の 2 形式で出力する
    # (後者は 1 行目が "# " 見出しでないノート) ので両方を扱う
    # 既定の limit (nb set limit) に引っかからないよう件数上限を明示する
    for line in (command nb list --no-color --no-indicator -n 100000 2>/dev/null)
        set -l m (string match -r '^\[(\d+)\]\s+(.*)$' -- $line)
        or continue
        set -l id $m[2]
        set -l title $m[3]
        set -l quoted (string match -r '^\S+ · "(.*)"$' -- $title)
        and set title $quoted[2]
        if test "$title" = "$label"
            if set -q _flag_print
                command nb show --print --no-color $id
            else
                command nb edit $id
            end
            return 0
        end
    end

    if set -q _flag_print
        echo "ノート '$label' はありません" >&2
        return 1
    end

    # 見つからなければ新規作成
    echo "ノート '$label' を新規作成します"
    command nb add --title "$label" --edit
end
