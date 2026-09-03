# 統合元の記録

このブランチは `rc2026_base/main` を共通基盤として、各チームの機能を画面・業務単位で取り込むための検証用統合版です。

## 基準コミット

| 範囲 | ブランチ | SHA |
| --- | --- | --- |
| 共通基盤 | `rc2026_base/main` | `ecd6bdcb87de965fa3b264e9d8f47ffb8cdb0024` |
| team1 | `rc2026_team1/main` | `91c4cc1749a8a610ea0ec72bd0d032c82f680b31` |
| team2 | `rc2026_team2/develop` | `90fd0c1c7ace6bb9d693f34457f862a2b52ea5f1` |
| team3 | `rc2026_team3/main` | `05b082c245a7ba079a4dd9574ac49d403a945411` |
| team4 | `rc2026_team4/main` | `03b1bb578358b3f14c338e9e36dc806b3f6ff727` |
| team5 | `rc2026_team5/main` | `5736d04a91aca41a922e32d9bf7f45a726d3fd99` |
| team6 | `rc2026_team6/main` | `fa55aaf21a8ad713bd55aca462efc734ffca5ed0` |

## 取り込み方針

- `rc2026_base` の7テーブルとモデルを正とし、チーム固有のmigration・schema更新・認証情報・ルート直下の重複モデルは取り込まない。
- 既存のViewと操作は可能な限り残し、競合するController・routeだけ統合する。
- 業務操作は `WorkRequest.register!`、`Availability.register_or_update!`、`Assignment.assign!` など共通Modelメソッドへ接続し、変更履歴を残す。
- 自動仮割当や全解除のようなDBを変更する操作はGETからPOST/DELETEへ修正する。

## 取り込まないもの

- team6の重複防止migrationと、それに伴う `db/schema.rb` の変更
- team6のroot直下に置かれた重複 `staff_member.rb`
- team5/team1の重複seed・作業用ファイル（基盤seedを正とする）
- CIや開発環境の認証情報・team固有の壊れたインフラ設定

## 上流CIの確認

2026-09-03時点で、team3・team5・team6の最新mainではCI失敗履歴を確認した。team2の基準 `develop` には対象CI履歴が無かったため、成功済みとは扱わず、統合ブランチ上で個別に検証する。上流の結果を理由に壊れた設定をコピーせず、統合側では基盤のworkflowを維持する。
