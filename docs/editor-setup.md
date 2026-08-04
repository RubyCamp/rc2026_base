# エディター設定

## 使用するエディター

このプロジェクトではVisual Studio Codeを使用する。

開発環境はDev Containersを利用し、RubyやRailsのコマンドはDev Container内で実行する。

## 必須の準備

次をインストールする。

- Visual Studio Code
- Docker Desktop
- Dev Containers拡張機能

Visual Studio Codeでリポジトリを開き、コマンドパレットから次を実行する。

```text
Dev Containers: Reopen in Container
```

ターミナルが次のように表示されれば、Dev Container内である。

```text
vscode ➜ /workspaces/rc2026_base (main) $
```

## 現在の共通設定

現在、このリポジトリには次の共通設定ファイルは置いていない。

- `.vscode/settings.json`
- `.vscode/extensions.json`
- `.editorconfig`

そのため、保存時の自動整形やインデント設定は、各自のVisual Studio Code設定に依存する。

## コードスタイルの確認

RubyコードはRuboCopで確認する。

```bash
bin/rubocop
```

正常な場合は次のように表示される。

```text
no offenses detected
```

自動修正可能な違反を直す場合は、変更内容を確認できる状態で実行する。

```bash
bin/rubocop -a
```

自動修正後は、必ず差分とテストを確認する。

```bash
git diff
bin/rails test
```

## ファイル保存後の確認

```bash
git diff --check
git status --short
```

`git diff --check`で何も表示されなければ、末尾の空白や不正な改行はない。

## Markdownの編集

READMEや`docs`配下の資料はMarkdown形式で記述する。

見出しは次のように書く。

```markdown
# 文書タイトル

## 大見出し

### 小見出し
```

コマンドはコードブロックで囲む。

```markdown
```bash
bin/rails test
```
```

## ターミナルの再起動

現在のターミナルが入力待ちになった場合は、`Ctrl + C`で処理を中断する。

ターミナル自体を終了する場合は、Visual Studio Codeのターミナル右上にあるごみ箱を押し、`＋`で新しいターミナルを開く。

## Dev Containerの再構築

DockerやDev Containerの設定を変更した場合は、コマンドパレットから次を実行する。

```text
Dev Containers: Rebuild Container
```

通常の再接続では次を使用する。

```text
Dev Containers: Reopen in Container
```
