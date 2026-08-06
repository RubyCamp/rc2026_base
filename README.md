# Ruby合宿 勤務調整システム

Ruby合宿で勤務調整システムを実装するためのRails共通基盤です。

業務データはPostgreSQLで管理し、画面はERB、Hotwire、Stimulus、Bootstrapを利用して実装します。

## 最初に行うこと

1. Docker Desktopを起動する
2. Visual Studio Codeでこのリポジトリを開く
3. `Dev Containers: Reopen in Container`を実行する
4. Dev Container内で次を実行する

```bash
bin/setup --skip-server
bin/rails db:seed
bin/dev
```

5. ブラウザで`http://localhost:3000`を開く

## データベース

development環境とproduction環境では`DATABASE_URL`を使用します。

test環境では`TEST_DATABASE_URL`を使用します。

接続先を切り替える場合は、Railsのコードを変更せず、環境変数を変更します。

## 使用バージョン

- Ruby 3.4.10
- Rails 8.1.3.1
- PostgreSQL 16.1
- ERB
- Hotwire
- Stimulus
- Bootstrap
- Minitest

## よく使うコマンド

### 初回セットアップ

```bash
bin/setup --skip-server
```

### 基準データの投入

```bash
bin/rails db:seed
```

### サーバーの起動

```bash
bin/dev
```

### Railsテスト

```bash
bin/rails test
```

### コードスタイルの確認

```bash
bin/rubocop
```

### セキュリティ確認

```bash
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/importmap audit
```

### 全確認の一括実行

```bash
bin/ci
```

## 資料

- [システム概要](docs/overview.md)
- [共通基盤とチームの実装範囲](docs/common-base.md)
- [データアクセス方針](docs/data-access-policy.md)
- [ドメインモデル](docs/domain-model.md)
- [ER図](docs/er-diagram.md)
- [seed方針](docs/seed-policy.md)
- [変更記録とデバッグ機能](docs/change-events.md)
- [開発環境](docs/development-environment.md)
- [テストと確認方法](docs/testing.md)
- [ブランチ運用](docs/branch-strategy.md)
- [エディター設定](docs/editor-setup.md)
- [画面実装方針](docs/ui-guidelines.md)
- [外部アセット](docs/third-party-assets.md)
