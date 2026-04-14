function nbs --description "tmuxセッション名に紐づくnbノートを開く/作成する"
    # tmuxセッション外なら終了
    if not set -q TMUX
        echo "tmuxセッション外では使えません"
        return 1
    end

    set -l session_name (tmux display-message -p '#S')

    if test -z "$session_name"
        echo "tmuxセッション名を取得できませんでした"
        return 1
    end

    # セッション名と完全一致するタイトルのノートを検索
    set -l titles (command nb list --no-color --no-id --no-indicator 2>/dev/null)
    set -l ids (command nb list --no-color --no-indicator 2>/dev/null | string match -r '\[(\d+)\]' --groups-only)

    for i in (seq (count $titles))
        if test "$titles[$i]" = "$session_name"
            command nb edit $ids[$i]
            return 0
        end
    end

    # 見つからなければ新規作成
    echo "ノート '$session_name' を新規作成します"
    command nb add --title "$session_name" --edit
end
