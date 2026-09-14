function nbs --description "herdr workspace の label に紐づく nb ノートを開く/作成する"
    # herdr の pane 外なら終了
    if test "$HERDR_ENV" != 1
        echo "herdr の pane 外では使えません"
        return 1
    end

    if test -z "$HERDR_WORKSPACE_ID"
        echo "HERDR_WORKSPACE_ID が設定されていません"
        return 1
    end

    # workspace の label をノート名として使う (tmux セッション名の代替)
    set -l label (command herdr workspace get "$HERDR_WORKSPACE_ID" 2>/dev/null | jq -r '.result.workspace.label // empty')

    if test -z "$label"
        echo "workspace の label を取得できませんでした (herdr workspace rename でラベルを付けてください)"
        return 1
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
            command nb edit $id
            return 0
        end
    end

    # 見つからなければ新規作成
    echo "ノート '$label' を新規作成します"
    command nb add --title "$label" --edit
end
