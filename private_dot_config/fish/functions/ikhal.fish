function ikhal --description "vdirsyncer 自動同期付き ikhal ラッパー"
    # 事前 sync: 失敗しても ikhal の起動は続行する
    echo "[ikhal] Google Calendar を同期中..."
    if not vdirsyncer sync google_calendar
        echo "[ikhal] 警告: 事前同期に失敗しました。続行します。"
    end

    # ikhal 本体を実行 (command を使って関数の再帰呼び出しを回避)
    command ikhal $argv

    # 事後 sync: ikhal 終了後に書き戻す
    echo "[ikhal] Google Calendar に書き戻し中..."
    if not vdirsyncer sync google_calendar
        echo "[ikhal] 警告: 事後同期に失敗しました。"
    end
end
