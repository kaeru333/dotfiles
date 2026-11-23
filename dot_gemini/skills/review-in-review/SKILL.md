---
name: review-in-review
description: >-
  GitHub Project の "In review" の issue を code-reviewer サブエージェントで必ずレビューし, ラベルとボード移動で分離する
---

# review-in-review

GitHub Project の Status が "In review" の issue を，code-reviewer サブエージェントで **必ず** レビューする．レビュー済みは `claude-reviewed` ラベルと「Reviewed」カラムへの移動で分離する．

引数 ユーザーの依頼内容 (引数指定があればその値) を project 番号として使う．空なら `3`（shogi_explain_tree）を既定とする．

## 義務（MANDATORY）

- 対象 issue が1件以上あれば，**全件を必ずレビューする**．スキップ・省略・ユーザーへの確認待ちは禁止．
- レビューは必ず `code-reviewer` サブエージェントを `invoke_subagent` ツール (Claude Code の Task ツール相当)で起動して行う．メインスレッドで直接レビュー本文を書かない．
- 複数件あれば，サブエージェントは **並列** で起動する．
- レビュー完了後は **必ず** ラベル付与とボード移動（後述）で分離する．

## 1. 対象 issue とメタ情報の取得

owner と project 番号を決め，1回の GraphQL でメタ情報（projectId / statusFieldId / Reviewed の option id）と対象 issue を取得する．`<NUMBER>` は上で決めた project 番号に置き換える．

```bash
OWNER=$(gh api user --jq .login)
DATA=$(gh api graphql -f login="$OWNER" -F number=<NUMBER> -f query='query($login:String!,$number:Int!){user(login:$login){projectV2(number:$number){id title field(name:"Status"){... on ProjectV2SingleSelectField{id options{id name}}} items(first:50){nodes{id content{__typename ... on Issue{number title url state repository{nameWithOwner} labels(first:30){nodes{name}}}} fieldValueByName(name:"Status"){... on ProjectV2ItemFieldSingleSelectValue{name}}}}}}}')

# --- メタ情報（移動に使う ID） ---
echo "$DATA" | jq -r '.data.user.projectV2 | "projectId=\(.id)","statusFieldId=\(.field.id)","reviewedOptionId=\((.field.options[]|select(.name=="Reviewed")|.id) // "MISSING")"'

# --- 対象: Status が "In review" かつ claude-reviewed ラベル無し ---
# 出力 = itemId<TAB>owner/repo<TAB>issue番号<TAB>タイトル
echo "$DATA" | jq -r '.data.user.projectV2.items.nodes[] | select(.content.__typename=="Issue") | select(.fieldValueByName.name=="In review") | select((.content.labels.nodes//[])|map(.name)|index("claude-reviewed")|not) | "\(.id)\t\(.content.repository.nameWithOwner)\t\(.content.number)\t\(.content.title)"'
```

- 対象行が空なら，「レビュー対象の In review issue はありません（全件レビュー済み）．」と報告して終了する．
- `reviewedOptionId=MISSING` の場合は，「ボードに『Reviewed』カラムが無いため，ボード移動はスキップします（ラベルのみ付与）．GitHub の Project UI で Status に『Reviewed』を1つ追加すると次回から看板でも分離されます．」と警告する．

## 2. 各 issue を code-reviewer サブエージェントでレビュー

対象 issue **1件ごと** に `invoke_subagent` ツール (Claude Code の Task ツール相当)で `code-reviewer` サブエージェントを起動する（複数あれば並列）．各サブエージェントへ次を指示する．

- 対象 issue: `owner/repo#番号`（タイトルも渡す）．
- レビュー対象コードの特定（この優先順で探す）:
  1. この issue を close / 参照する **open PR** があれば，その差分 `gh pr diff <PR番号> -R <owner/repo>` をレビュー．PR は `gh pr list -R <owner/repo> --state open --json number,title,body,headRefName` から issue 番号への参照やブランチ名で判断する．
  2. 無ければ issue 番号に対応するブランチ（例 `issue-<番号>`，`<番号>-*`，`feature/<番号>-*`）を `git ls-remote` 等で探し，あれば `git fetch` 後に `git diff origin/main...origin/<branch>` をレビュー．
  3. それも無ければ issue 本文 `gh issue view <番号> -R <owner/repo>` を仕様・設計としてレビュー（コード差分が無い旨を明記）．
- 観点: バグ，セキュリティ，性能，可読性．各指摘に重大度 CRITICAL / HIGH / MEDIUM / LOW を付ける．
- 出力は **日本語**．句読点は全角カンマ「，」と全角ピリオド「．」を使う．全角括弧は使わない．
- レビュー結果を `gh issue comment <番号> -R <owner/repo> --body "<本文>"` で投稿．本文末尾に `🤖 review-in-review による自動レビュー` を付ける．
- サブエージェントはメインスレッドへ，issue 番号・レビュー対象（PR / branch / 本文）・重大度別件数を短く返す．

## 3. 分離（ラベル付与 ＋ ボード移動）

各サブエージェントのレビュー完了後，メインスレッドで対象 issue ごとに **必ず** 実行する．`<itemId>` は手順1で取得した値，ID 各種も手順1の出力を使う．

```bash
# ラベルが無ければ作成（既存ならスキップ）
gh label create claude-reviewed -R <owner/repo> -c 5319E7 -d "review-in-review でレビュー済み" 2>/dev/null || true
# ラベル付与
gh issue edit <番号> -R <owner/repo> --add-label claude-reviewed
# ボード移動（reviewedOptionId が MISSING でない場合のみ）
gh project item-edit --id <itemId> --field-id <statusFieldId> --project-id <projectId> --single-select-option-id <reviewedOptionId>
```

- `reviewedOptionId=MISSING` のときはボード移動コマンドを実行せず，ラベル付与のみ行う．

## 4. まとめと通知

全件の処理後:

- レビューした issue 一覧（対象が PR / branch / 本文のどれか），重大度別サマリ，ボード移動の成否を表示する．
- `notify-slack "review-in-review: <project名> の In review issue <N>件をレビューしました（CRITICAL <a>, HIGH <b>）"` で Slack 通知する．

## 補足: 再レビューのやり方

レビュー後に修正してもう一度レビューさせたいときは，`claude-reviewed` ラベルを外し，Status を「In review」へ戻してから再度 `/review-in-review` を実行する．
