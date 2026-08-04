# 開発環境

## 使用する環境

このプロジェクトは、DockerとVisual Studio CodeのDev Containersを利用して開発する。

主なバージョンは次のとおりである。

- Ruby 3.4.10
- Rails 8.1.3.1
- PostgreSQL 16.1
- Node.jsを必要としないImportmap構成
- ERB
- Hotwire
- Stimulus
- Bootstrap

## 初回起動

### 1．Docker Desktopを起動する

WindowsではDocker DesktopとWSLを使用する。

### 2．リポジトリを開く

Visual Studio Codeで`rc2026_base`ディレクトリを開く。

### 3．Dev Containerを開く

コマンドパレットから次を実行する。

```text
Dev Containers: Reopen in Container
```

ターミナルの表示が次のようになれば、Dev Container内である。

```text
vscode ➜ /workspaces/rc2026_base (main) $
```

### 4．セットアップする

Dev Container内で次を実行する。

```bash
bin/setup --skip-server
bin/rails db:seed
```

### 5．サーバーを起動する

```bash
bin/dev
```

ブラウザで次を開く。

```text
http://localhost:3000
```

## コマンドを実行する場所

### WSL側で実行するもの

Docker Composeやリポジトリの複製など、コンテナ外の操作はWSLで実行する。

例：

```bash
docker compose -f .devcontainer/compose.yaml up -d --build
git clone https://github.com/RubyCamp/rc2026_base.git
```

### Dev Container内で実行するもの

Rails、Ruby、Bundle、テストなどはDev Container内で実行する。

例：

```bash
bin/rails test
bin/ci
bin/rubocop
bundle install
```

## データベース

development環境とproduction環境では`DATABASE_URL`を使用する。

test環境では`TEST_DATABASE_URL`を使用する。

test用DBには、development用DBとは異なるデータベース名を指定する。

## データベースの準備

```bash
bin/rails db:prepare
```

test用DBを準備する場合は次を実行する。

```bash
RAILS_ENV=test bin/rails db:prepare
```

## 基準データ

```bash
bin/rails db:seed
```

基準データは、画面確認や動作確認で同じ状態を再現するために使用する。

## Dev Containerの再起動

Visual Studio Codeのコマンドパレットから、次のいずれかを実行する。

```text
Dev Containers: Reopen in Container
Dev Containers: Rebuild Container
```

設定やDockerfileを変更した場合は、`Rebuild Container`を使用する。

## ターミナルの再起動

Visual Studio Codeのターミナル右上にあるごみ箱のアイコンで現在のターミナルを終了し、`＋`を押して新しいターミナルを開く。

## 注意事項

- 既存のRailsアプリケーションに対して`rails new`を再実行しない
- development用DBとtest用DBを同じ名前にしない
- Railsコマンドは原則としてDev Container内で実行する
- Docker Desktopが起動していることを確認する
