# ChangeEvent

ChangeEventは、勤務依頼、勤務可否、割当の変更を確認するための記録である。

## 対象

- work_request
- availability
- assignment

## 変更種別

- created
- updated
- cancelled
- deleted
- assigned
- confirmed
- unassigned

## 確認状態

- pending
- reviewed

確認済みにした日時はreviewed_atへ保存する。

## 発生元

- operation：通常の業務操作
- seed：初期データ
- debug：開発時の表示確認

## 削除方針

通常の変更記録は削除しない。

sourceがdebugであり、開発環境でENABLE_CHANGE_EVENT_DEBUG=trueの場合だけremove_debug!による削除を許可する。

target_idには外部キーを付けない。対象の業務データが削除された後も、変更記録を残すためである。
