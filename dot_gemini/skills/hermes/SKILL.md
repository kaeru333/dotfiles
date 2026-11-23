---
name: hermes
description: >-
  XServer VPS で常駐している Hermes Agent に ssh 越しで質問し，回答を受け取る (A2A の代わり)
---

# hermes

VPS (`ssh hermes`) で常時動いている Hermes Agent に ユーザーの依頼内容 (引数指定があればその値) を問い合わせ，回答を日本語で要約して返す．

Claude Code と Hermes v0.21 はどちらも A2A に対応していないため，`hermes -z` (one-shot モード) を ssh 越しに呼ぶ．
Hermes 側は記憶・Slack・Gmail・Google カレンダー・kanban・`~/` のメモにアクセスできる．

## 手順

1. 次の形で実行する．timeout は 600000 ms にする．

   ```bash
   ssh hermes 'export PATH=$HOME/.local/bin:$PATH; cd ~ && hermes -z "<質問>．調査だけを行い，誰にもメッセージを送ったり返信したりしないこと．回答は日本語で．"' 2>&1 | tail -100
   ```

   - `<質問>` は ユーザーの依頼内容 (引数指定があればその値) をもとに，知りたい項目を列挙した具体的な文に整える．
   - シングルクォートが入ると壊れるので，質問文からは `'` を除く．
2. 回答をユーザーに要約して伝える．Hermes が「不明」とした項目と，確認が残っている項目は明示する．

## 注意

- `-z` は承認プロンプトを自動で通す．送信・返信・削除などの副作用をユーザーが明示的に頼んだとき以外は，必ず「調査のみ」の制約を付ける．
- `Native returned a tool outside the current host inventory` や `didn't answer after 3 attempts` が出たら，プロバイダ側の一時的な不調のことが多い．1 回だけ再試行する．
- 状態の確認には `ssh hermes 'systemctl --user status hermes-gateway'` を使う．
