---
name: hunk-review
description: ユーザーが hunk (ターミナル diff ビューア) でレビュー中のセッションに CLI から参加する。hunk のインラインコメントの読み書き・ナビゲート・リロードを行う。「hunk でレビュー」「hunk のコメント見て」などで使う。
---

# hunk-review (ラッパー)

hunk 本体に同梱されている公式スキルを読み込んで、その指示に従うこと。
(nix 管理のためパスがバージョンごとに変わる。ハードコードせず毎回解決する)

1. `hunk skill path` を実行してスキルの実パスを取得する
2. そのファイルを Read して、以降はその内容(hunk session CLI の使い方)に従う

要点(本体スキル読了までのつなぎ):

- TUI はユーザーのもの。`hunk diff` / `hunk show` を自分で起動しない。操作は必ず `hunk session *` 経由
- セッション確認: `hunk session list` / 構造把握: `hunk session review --repo . --json`
- ユーザーが TUI で `c` キーで書いたノートを読む: `hunk session comment list --repo . --type user`
- 自分のコメント追加: `hunk session comment add --repo . --file <path> --new-line <n> --summary "..."`(複数は `comment apply --stdin` でバッチ)
- 話題にする箇所へユーザーの画面を移動: `hunk session navigate --repo . --file <path> --hunk <n>`
