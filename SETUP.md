# 新 Mac セットアップ手順 (再現性 / 冪等性ランブック)

PC 入替時にこの環境を再構築するための手順。各ステップは**冪等**(再実行しても壊れない)。
「機微情報を含むデータはクラウドへ出さない」方針のため、一部は **GitHub clone ではなく手動コピー**で運ぶ。

## 全体像 — 何がどこから復元されるか

| 対象 | 復元方法 | 場所 |
|---|---|---|
| shell / git / starship / nvim / CLI ツール / Brewfile | **dotfiles**(clone + install.sh + home-manager) | このリポジトリ |
| `~/.claude` 全体(symlink 先) | dotfiles の `home/.claude`(install.sh が symlink を張る) | このリポジトリ |
| Claude skills / settings.json / statusline | dotfiles(追跡対象) | `home/.claude/` |
| **Claude agents(BFF/VPA)** | **private marketplace のプラグイン**を再追加 → `enabledPlugins` で有効化 | `A-CMS/xn6-cc-marketplace` |
| 旧ローカル agents(レガシー・退役予定) | 任意。`claude-local-backup` を手動コピー → restore.sh | `~/claude-local-backup` |
| **恒久知識(旧 Claude memory)** | **notes に同梱のテキスト**(`notes/knowledge/*.md`)。recall は `~/cc/CLAUDE.md` の索引 | `notes/knowledge/` |
| A-CMS / 個人のコードリポジトリ | **clone**(`bin/clone-repos.sh`) | `~/dev/src/github.com/...` |
| **notes 知識ベース**(remote 無し) | **手動コピー** | `~/dev/src/github.com/akihiko-minamisawa/notes` |
| **~/cc ワークスペース**(local-only) | **手動コピー**(git 履歴ごと) | `~/cc` |
| MCP コネクタ / gh / Azure 認証 | **手動再認証**(スクリプト化不可) | 下記チェックリスト |

> 旧 PC で実施しておくこと: 手動コピー対象(`notes` / `~/cc`、レガシー agents が要るなら `~/claude-local-backup`)を
> 外付け or AirDrop で新 PC へ。恒久知識は `notes` に入っているので別途バックアップ不要。

---

## 0. 前提ツールのインストール

```sh
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Nix (Determinate Systems installer 等) → flake + home-manager を使うため
#   インストール後シェル再起動

# gh CLI（Brewfile にも入るが、clone-repos.sh の前に最低限必要）
brew install gh
```

## 1. SSH 鍵と GitHub 認証

```sh
ssh-keygen -t ed25519 -C "akihiko-minamisawa"      # 新しい鍵（または旧鍵を ~/.ssh へ手動コピー）
gh auth login                                       # SSH プロトコルを選択
gh auth status                                      # 確認
```

## 2. dotfiles の取得と適用

```sh
mkdir -p ~/dev/src/github.com/akihiko-minamisawa
cd ~/dev/src/github.com/akihiko-minamisawa
git clone ssh://git@github.com/akihiko-minamisawa/dotfiles
cd dotfiles

./install.sh                        # home/ 配下を $HOME へ symlink（~/.claude もここで張られる）
brew bundle --file=~/Brewfile       # パッケージ復元
home-manager switch --flake .#aki   # nix 管理分（zsh/git/starship/CLI tools）を適用
```

> `install.sh` は既存実体を `*.backup` に退避してから symlink。既存 symlink は張り直し。再実行可。

## 3. コードリポジトリの一括 clone

```sh
~/dev/src/github.com/akihiko-minamisawa/dotfiles/bin/clone-repos.sh
```

A-CMS と akihiko-minamisawa の全リポジトリを `~/dev/src/github.com/<owner>/<repo>` へ。既存はスキップ(fetch のみ)。

## 4. ローカル専用データの手動コピー & 復元

旧 PC からコピーしてくる(remote が無い/機微情報のため):

```
~/dev/src/github.com/akihiko-minamisawa/notes      # zk 知識ベース + knowledge/(恒久知識)(.git ごと)
~/cc                                               # 作業ワークスペース(.git ごと)
~/claude-local-backup                              # ※レガシー agents が要る場合のみ
```

コピー後:

```sh
# zk インデックス再生成(notebook.db は gitignore のため)
cd ~/dev/src/github.com/akihiko-minamisawa/notes && zk index

# ~/cc から知識ベースへの symlink を再作成(cc では gitignore のため)
ln -sfn ~/dev/src/github.com/akihiko-minamisawa/notes ~/cc/notes

# (任意) レガシーのローカル agents を ~/.claude へ戻す場合のみ
# ~/claude-local-backup/bin/restore.sh
```

> 恒久知識(旧 memory)は `notes/knowledge/*.md` にテキストで入っており、上の notes コピーで一緒に復元される。
> Claude の recall は `~/cc/CLAUDE.md` の「恒久知識の管理」索引が担うので、auto-memory の復元作業は不要。

## 5. 手動再認証チェックリスト(自動化不可)

- [ ] **Claude Code MCP コネクタ**: `claude` 起動 → `/mcp` で各コネクタを認証
      - Atlassian / Slack / Gmail / Google Calendar / Google Drive / Notion / Datadog
      - ⚠️ **Microsoft 365 (Outlook)** は日産の条件付きアクセスでブロックされる既知制約(認証しても弾かれる)
- [ ] **Claude プラグイン / agents**: marketplace を再追加 → `enabledPlugins` で有効化(settings.json に定義あり)
      - `A-CMS/xn6-cc-marketplace`(private): `bff-local-env` / `mock-vehicle-tools` / `nissan-bff-agents` / `nissan-vpa-agents`
      - `anthropics/claude-plugins-official`: `notion` / `datadog`
- [ ] **Azure**: `az login`(Key Vault シークレット参照に必要。BFF ローカル env 生成等)
- [ ] **gh**: 済(手順1)。token scope は `repo, read:org, gist`
- [ ] **mise / 各言語ランタイム**: `mise install`(必要に応じ)

## 6. 検証

```sh
cd ~/cc && claude          # (alias: home-manager の `cc`)
#  → Task で nc-bff-* / nc-vpa-* 等サブエージェントが見えるか(marketplace プラグイン有効化の確認)
#  → CLAUDE.md の索引から notes/knowledge/*.md が引けるか
ls -l ~/.claude            # dotfiles への symlink になっているか
head ~/cc/notes/knowledge/README.md       # 恒久知識の索引が読めるか
head ~/cc/notes/jp-bff-members.md         # notes symlink 経由で読めるか
```

---

## 定期メンテ(旧 PC で普段から)

```sh
cd ~/.../notes && git add -A && git commit  # 知識ベース + knowledge/(恒久知識)の履歴
cd ~/cc && git add -A && git commit          # 作業ワークスペースの履歴
# (レガシー agents をまだ使うなら) ~/claude-local-backup/bin/backup.sh
```
