# 画面実装方針

## 基本方針

このプロジェクトでは、RailsのERBとBootstrapを利用して業務画面を実装する。

画面ごとに独自の構造や見た目を作りすぎず、共通レイアウトとBootstrapの部品を優先して利用する。

## 共通レイアウト

共通レイアウトは次のファイルで管理する。

```text
app/views/layouts/application.html.erb
```

画面の言語は日本語とする。

```html
<html lang="ja">
```

ページ本文は、共通の`main`要素内へ表示される。

```html
<main class="container py-4 py-md-5">
```

## ナビゲーション

共通のナビゲーションには、現在次のリンクがある。

- 勤務依頼
- スタッフ

新しい主要画面を追加する場合は、必要に応じて共通ナビゲーションへリンクを追加する。

## Bootstrap

BootstrapのCSSとJavaScriptは、次のファイルをローカルから読み込んでいる。

```text
app/assets/stylesheets/bootstrap.min.css
app/assets/javascripts/bootstrap.bundle.min.js
```

レイアウトでは次の名前で読み込む。

```erb
<%= stylesheet_link_tag "bootstrap.min",
                        "data-turbo-track": "reload" %>

<%= javascript_include_tag "bootstrap.bundle.min",
                           defer: true,
                           "data-turbo-track": "reload" %>
```

## 独自CSS

アプリケーション固有のCSSは`application`から読み込む。

```erb
<%= stylesheet_link_tag "application",
                        "data-turbo-track": "reload" %>
```

Bootstrapで表現できる内容はBootstrapを優先し、独自CSSを必要以上に増やさない。

## よく使用する部品

### ページ見出し

ページの先頭には、内容が分かる見出しを置く。

```erb
<h1 class="h2 mb-4">勤務依頼</h1>
```

### 一覧

一覧データには、内容に応じてBootstrapのtableまたはcardを使用する。

```erb
<div class="table-responsive">
  <table class="table table-striped align-middle">
  </table>
</div>
```

横幅が小さい画面でも確認できるように、表は`table-responsive`で囲む。

### ボタン

操作の意味に応じてBootstrapのボタンを使い分ける。

```erb
<%= link_to "詳細", work_request_path(work_request),
                    class: "btn btn-outline-primary" %>
```

重要な確定操作には`btn-primary`、削除などの注意が必要な操作には`btn-danger`を使用する。

### 状態表示

statusなどの短い状態はbadgeで表示できる。

```erb
<span class="badge text-bg-secondary">
  <%= work_request.status %>
</span>
```

### 成功メッセージ

成功メッセージは`notice`を利用する。

```erb
<div class="alert alert-success" role="status">
  <%= notice %>
</div>
```

### エラーメッセージ

エラーメッセージは`alert`を利用する。

```erb
<div class="alert alert-danger" role="alert">
  <%= alert %>
</div>
```

## フォーム

フォームは`form_with`を使用する。

入力欄には、内容を表すlabelを付ける。

```erb
<%= form.label :title, "勤務依頼名", class: "form-label" %>
<%= form.text_field :title, class: "form-control" %>
```

必須項目や入力エラーが分かるように表示する。

## アクセシビリティ

- 画像には内容に応じた代替テキストを付ける
- 入力欄にはlabelを付ける
- 色だけで状態を伝えない
- ボタンやリンクの目的が文字から分かるようにする
- 見出しの順序を飛ばさない
- ナビゲーションには内容を表す`aria-label`を付ける

## レスポンシブ対応

Bootstrapのgridやレスポンシブクラスを利用する。

小さい画面で横方向にはみ出さないことを確認する。

共通ナビゲーションは、画面幅が狭い場合に折りたたまれる。

## JavaScript

画面操作にJavaScriptが必要な場合はStimulusを利用する。

Controllerは次の場所へ置く。

```text
app/javascript/controllers
```

Turboで画面遷移した場合にも正しく動作する構成にする。

## 確認項目

画面を変更した場合は、次を確認する。

- PC幅で表示が崩れていない
- 画面幅を狭くしても操作できる
- ナビゲーションから移動できる
- 成功と失敗のメッセージが確認できる
- キーボードでもリンクやボタンを操作できる
- Railsテストと`bin/ci`が成功する
