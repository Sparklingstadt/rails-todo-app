# 単体テストとE2Eテスト

このアプリはRails標準のMinitestを使います。E2EはCapybaraとSeleniumで実際のChromeを起動し、Railsのサーバーとテスト用SQLiteを通して検証します。APIやDBの応答はモックしていません。

## 実行する

プロジェクトのフォルダーで実行します。

```sh
# 単体テスト：モデル13件、表示ヘルパー5件
bin/rails test test/models test/helpers

# HTTPリクエストテスト：13件
bin/rails test test/controllers

# 上の単体・HTTPリクエストをまとめて実行：31件
bin/rails test

# E2Eテスト：10件（ヘッドレスChrome）
bin/rails test:system
```

E2EにはGoogle Chromeが必要です。ChromeDriverはSelenium Managerが取得します。初回の取得にはネット接続が必要です。開発サーバーを事前に起動する必要はなく、Capybaraが空いているポートでテストサーバーを起動します。

## 何を確かめるか

| 種別 | ファイル | 主な確認内容 |
| --- | --- | --- |
| モデルの単体テスト | `test/models/task_test.rb` | 必須入力、文字数境界、空白除去と保存、初期値、うるう日、期限超過、完了／未完了の検索、並び順、DB制約 |
| ヘルパーの単体テスト | `test/helpers/tasks_helper_test.rb` | 期限なし・今日・明日・日付の表示、年越し、日本時間0時での表示切り替え |
| HTTPリクエスト | `test/controllers/tasks_controller_test.rb` | CRUD、許可した項目のみの保存、入力エラー、404、HTMLエスケープ、完了操作の再送 |
| 基本E2E | `test/system/tasks_test.rb` | 作成から削除までの一連の操作、入力エラー、モバイルでの追加 |
| 追加E2E | `test/system/task_management_test.rb` | 全項目の保存と再読み込み、期限の削除、編集エラーからの修正、絞り込みと進捗、削除キャンセル、最後のタスク削除、初回追加、編集キャンセル、HTML文字列、モバイルの下書き保持と長文 |

テストを追加するときは、「壊れると利用者が何に困るか」からケースを選びます。単体テストは小さな規則と境界値、E2Eは複数の画面・処理をまたぐ利用者の操作を中心にします。

## データの分離

- テストDBは `storage/test.sqlite3`、開発DBは `storage/development.sqlite3` です。
- `test/fixtures/tasks.yml` にある共通データと、各テスト内の専用データを使用します。
- 各テストの変更はトランザクションで取り消します。実行順序に依存させません。
- `test/test_helper.rb` は `RAILS_ENV` が `test` 以外なら、Railsを読み込む前に停止します。
- 単体・HTTPリクエスト・E2Eのコマンドは順番に実行してください。独立したプロセスで同じテストDBを同時に操作する構成にはしていません。

## 失敗を調べる

失敗したテストのファイルと行番号が出力されます。その行を指定して再実行できます。

```sh
bin/rails test test/models/task_test.rb:4
```

E2Eは `bin/rails test test/system/task_management_test.rb` で対象ファイルを絞れます。失敗時の画面は `tmp/screenshots`、Railsの処理記録は `log/test.log` に出力されます。

Turboによる遷移は非同期なので、遷移先のURLや保存完了の表示を確認してから次の操作へ進みます。固定秒数の待機や、失敗を隠すための自動リトライは使用していません。

## CIでの実行

既存の `.github/workflows/ci.yml` で、`test` ジョブが単体・HTTPリクエストを、`system-test` ジョブがE2Eを実行します。今回追加したファイルも自動で対象になります。E2E失敗時はスクリーンショットをartifactとして保存します。

GitHub上の実行結果は [Actions](https://github.com/Sparklingstadt/rails-todo-app/actions/workflows/ci.yml)、ローカルでの実行結果は [検証記録](verification.md) を参照してください。
