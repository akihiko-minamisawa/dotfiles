# 新 Mac セットアップ手順 (再現性 / 冪等性ランブック)

PC 入替時にこの環境を再構築するための手順。各ステップは**冪等**(再実行しても壊れない)。
「機微情報を含むデータはクラウドへ出さない」方針のため、一部は **GitHub clone ではなく手動コピー**で運ぶ。

## 全体像 — 何がどこから復元されるか

| 対象 | 復元方法 | 場所 |
|---|---|---|
| shell / git / starship / nvim / CLI ツール | **dotfiles**(clone + `home-manager switch`) | このリポジトリ |
| Homebrew 一式(brew/cask/mas、宣言は `nix/darwin.nix`) | **dotfiles**(clone + `darwin-rebuild switch`) | このリポジトリ |
| `~/.claude` 全体(symlink 先) | dotfiles の `home/.claude`(home-manager が symlink を張る) | このリポジトリ |
| Claude skills / settings.json / statusline | dotfiles(追跡対象) | `home/.claude/` |
| **Claude agents(BFF/VPA)** | **private marketplace のプラグイン**を再追加 → `enabledPlugins` で有効化 | `A-CMS/xn6-cc-marketplace` |
| **恒久知識(旧 Claude memory)** | **notes に同梱のテキスト**(`notes/knowledge/*.md`)。recall は `~/cc/CLAUDE.md` の索引 | `notes/knowledge/` |
| A-CMS / 個人のコードリポジトリ | **clone**(`bin/clone-repos.sh`) | `~/dev/src/github.com/...` |
| **notes 知識ベース**(remote 無し) | **手動コピー** | `~/dev/src/github.com/akihiko-minamisawa/notes` |
| **~/cc ワークスペース**(local-only) | **手動コピー**(git 履歴ごと) | `~/cc` |
| MCP コネクタ / gh / Azure 認証 | **手動再認証**(スクリプト化不可) | 下記チェックリスト |

> 旧 PC で実施しておくこと: 手動コピー対象(`notes` / `~/cc`)を外付け or AirDrop で新 PC へ。
> 恒久知識は `notes/knowledge/` に入っているので別途バックアップ不要。
> agents は marketplace から復元する(ローカル `~/.claude/agents/` の旧定義は gitignore=非バックアップ。退役予定)。

---

## 0. 前提ツールのインストール

```sh
# Homebrew(nix-darwin が brew bundle の実行基盤として使う。casks/mas はこれ経由)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Nix (Determinate Systems installer 推奨 — daemon の ssl-cert-file を正しく設定する)
#   インストール後シェル再起動

# gh CLI(恒久版は home-manager が入れる。clone-repos.sh の前に暫定で必要なだけ)
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

# ユーザー環境: zsh/git/starship/CLI tools + 設定 symlink(~/.claude・~/.config/* もここで張られる)
#   初回は flakes 未設定なので NIX_CONFIG で bootstrap
NIX_CONFIG="experimental-features = nix-command flakes" \
  nix run home-manager -- switch --flake .#aki

# システム + Homebrew 一式: /etc・launchd + brew/casks/mas を宣言(nix/darwin.nix)から復元
#   ※ mas の前提: App Store にサインイン済み & Spotlight 有効(mdutil -s / で確認。
#      無効だと mas が既存アプリを認識できず再インストールを試みて失敗する)
sudo nix run nix-darwin -- switch --flake .#minamisawa-macbook
```

> 2回目以降は `home-manager switch --flake .#aki` / `sudo darwin-rebuild switch --flake .#minamisawa-macbook` だけでよい。
> パッケージ宣言の正: CLI ツール = `nix/home.nix` の home.packages、brew/cask/mas = `nix/darwin.nix` の homebrew ブロック。旧 `install.sh`・`home/Brewfile` は廃止済み。

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
```

コピー後:

```sh
# zk インデックス再生成(notebook.db は gitignore のため)
cd ~/dev/src/github.com/akihiko-minamisawa/notes && zk index

# ~/cc から知識ベースへの symlink を再作成(cc では gitignore のため)
ln -sfn ~/dev/src/github.com/akihiko-minamisawa/notes ~/cc/notes
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
```
