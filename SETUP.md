# 新 Mac セットアップ手順 (再現性 / 冪等性ランブック)

PC 入替時にこの環境を再構築するための手順。各ステップは**冪等**(再実行しても壊れない)。
「機微情報を含むデータはクラウドへ出さない」方針のため、一部は **GitHub clone ではなく手動コピー**で運ぶ。

## 全体像 — 何がどこから復元されるか

| 対象 | 復元方法 | 場所 |
|---|---|---|
| shell / git / starship / nvim / CLI ツール / Brewfile | **dotfiles**(clone + install.sh + home-manager) | このリポジトリ |
| `~/.claude` 全体(symlink 先) | dotfiles の `home/.claude`(install.sh が symlink を張る) | このリポジトリ |
| Claude skills / settings.json / statusline | dotfiles(追跡対象) | `home/.claude/` |
| **Claude agents / 各プロジェクト memory** | **claude-local-backup を手動コピー → restore.sh**(dotfiles では gitignore) | `~/claude-local-backup` |
| A-CMS / 個人のコードリポジトリ | **clone**(`bin/clone-repos.sh`) | `~/dev/src/github.com/...` |
| **notes 知識ベース**(remote 無し) | **手動コピー** | `~/dev/src/github.com/akihiko-minamisawa/notes` |
| **~/cc ワークスペース**(local-only) | **手動コピー**(git 履歴ごと) | `~/cc` |
| MCP コネクタ / gh / Azure 認証 | **手動再認証**(スクリプト化不可) | 下記チェックリスト |

> 旧 PC で実施しておくこと: `~/claude-local-backup/bin/backup.sh` を最後に1回実行してから、
> 手動コピー対象(`notes` / `~/cc` / `~/claude-local-backup`)を外付け or AirDrop で新 PC へ。

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
~/dev/src/github.com/akihiko-minamisawa/notes      # zk 知識ベース(.git ごと)
~/cc                                               # 作業ワークスペース(.git ごと)
~/claude-local-backup                              # Claude agents + memory + settings
```

コピー後:

```sh
# Claude の agents / memory を ~/.claude(=dotfiles/home/.claude)へ復元
~/claude-local-backup/bin/restore.sh

# zk インデックス再生成(notebook.db は gitignore のため)
cd ~/dev/src/github.com/akihiko-minamisawa/notes && zk index

# ~/cc から知識ベースへの symlink を再作成(cc では gitignore のため)
ln -sfn ~/dev/src/github.com/akihiko-minamisawa/notes ~/cc/notes
```

## 5. 手動再認証チェックリスト(自動化不可)

- [ ] **Claude Code MCP コネクタ**: `claude` 起動 → `/mcp` で各コネクタを認証
      - Atlassian / Slack / Gmail / Google Calendar / Google Drive / Notion / Datadog
      - ⚠️ **Microsoft 365 (Outlook)** は日産の条件付きアクセスでブロックされる既知制約(認証しても弾かれる)
- [ ] **Claude プラグイン**: marketplace(`A-CMS/xn6-cc-marketplace`, `anthropics/claude-plugins-official`)再取得 → `bff-local-env` / `notion` / `datadog` 有効化(settings.json に定義済み)
- [ ] **Azure**: `az login`(Key Vault シークレット参照に必要。BFF ローカル env 生成等)
- [ ] **gh**: 済(手順1)。token scope は `repo, read:org, gist`
- [ ] **mise / 各言語ランタイム**: `mise install`(必要に応じ)

## 6. 検証

```sh
cd ~/cc && claude          # (alias: home-manager の `cc`)
#  → /memory でメモリが復元されているか
#  → Task で bff-dev 等サブエージェントが見えるか(agents 復元確認)
ls -l ~/.claude            # dotfiles への symlink になっているか
cat ~/cc/notes/jp-bff-members.md | head   # notes symlink 経由で読めるか
```

---

## 定期メンテ(旧 PC で普段から)

```sh
~/claude-local-backup/bin/backup.sh        # agents/memory のスナップショット & commit(冪等)
cd ~/cc && git add -A && git commit         # 作業ワークスペースの履歴
cd ~/.../notes && git add -A && git commit  # 知識ベースの履歴
```
