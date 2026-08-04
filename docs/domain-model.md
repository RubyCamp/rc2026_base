# ドメインモデル

## Business

事業者を表すモデルである。

主な項目は次のとおりである。

- `name`：事業者名
- `contact_name`：担当者名
- `contact_phone`：連絡先
- `active`：利用状態
- `notes`：備考

### 関連

- 複数の`WorkRequest`を持つ
- 勤務依頼が存在する事業者は削除できない

### validation

- 事業者名は必須
- 担当者名は必須
- 連絡先は必須

## WorkRequest

事業者から受けた勤務依頼を表すモデルである。

主な項目は次のとおりである。

- `business_id`：依頼元の事業者
- `required_skill_id`：必要なスキル
- `title`：勤務依頼の名称
- `starts_at`：開始時刻
- `ends_at`：終了時刻
- `required_staff_count`：必要人数
- `status`：依頼状態
- `notes`：備考

### status

- `open`
- `draft`
- `confirmed`
- `cancelled`

### 関連

- 1つの`Business`に属する
- 必要スキルとして1つの`Skill`に属する
- 複数の`Assignment`を持つ
- `Assignment`を通して複数の`StaffMember`を持つ

### validation

- タイトルは必須
- 開始時刻は必須
- 終了時刻は必須
- 必要人数は1以上の整数
- 終了時刻は開始時刻より後であること

### 主な業務用メソッド

- `register!`
- `update_details!`
- `cancel!`
- `remove!`
- `with_staffing_shortage`
- `staffing_shortage_count`
- `staffing_sufficient?`

## StaffMember

スタッフを表すモデルである。

主な項目は次のとおりである。

- `name`：氏名
- `employment_status`：在籍状態
- `notes`：備考

### employment_status

- `active`
- `inactive`

### 関連

- 複数の`Availability`を持つ
- 複数の`Assignment`を持つ
- 複数の`StaffSkill`を持つ
- `StaffSkill`を通して複数の`Skill`を持つ

### validation

- 氏名は必須

### 主な検索用メソッド

- `for_list`
- `for_assignment`
- `available_for`
- `skilled_for`
- `available_during`

## Availability

スタッフの勤務可能または勤務不可能な時間帯を表すモデルである。

主な項目は次のとおりである。

- `staff_member_id`：対象スタッフ
- `starts_at`：開始時刻
- `ends_at`：終了時刻
- `status`：勤務可否
- `notes`：備考

### status

- `available`
- `unavailable`

### 関連

- 1人の`StaffMember`に属する

### validation

- 開始時刻は必須
- 終了時刻は必須
- 終了時刻は開始時刻より後であること

### 主な業務用メソッド

- `register_or_update!`
- `remove!`

## Assignment

勤務依頼に対するスタッフの割り当てを表すモデルである。

主な項目は次のとおりである。

- `work_request_id`：勤務依頼
- `staff_member_id`：割り当てるスタッフ
- `status`：割り当て状態
- `notes`：備考

### status

- `draft`
- `confirmed`

### 関連

- 1つの`WorkRequest`に属する
- 1人の`StaffMember`に属する

### validation

同じ勤務依頼に同じスタッフを重複して割り当てることはできない。

### 主な業務用メソッド

- `assign!`
- `confirm!`
- `unassign!`

## Skill

業務に必要なスキルを表すモデルである。

主な項目は次のとおりである。

- `code`：スキルコード
- `name`：スキル名
- `active`：利用状態

### 関連

- 複数の`StaffSkill`を持つ
- `StaffSkill`を通して複数の`StaffMember`を持つ
- 複数の`WorkRequest`から必要スキルとして参照される

### validation

- コードは必須
- コードは重複不可
- スキル名は必須

## StaffSkill

スタッフとスキルを関連付ける中間モデルである。

主な項目は次のとおりである。

- `staff_member_id`：スタッフ
- `skill_id`：スキル
- `proficiency_label`：習熟度などの表示

### 関連

- 1人の`StaffMember`に属する
- 1つの`Skill`に属する

### validation

- 習熟度の表示は必須
- 同じスタッフと同じスキルの組み合わせは重複不可

## ChangeEvent

業務データの変更記録を表すモデルである。

主な項目は次のとおりである。

- `target_type`：変更対象の種類
- `target_id`：変更対象のID
- `action_type`：操作の種類
- `summary`：変更内容
- `occurred_at`：発生日時
- `review_status`：確認状態
- `reviewed_at`：確認日時
- `source`：記録元

### target_type

- `work_request`
- `availability`
- `assignment`

### action_type

- `created`
- `updated`
- `cancelled`
- `deleted`
- `assigned`
- `confirmed`
- `unassigned`

### review_status

- `pending`
- `reviewed`

### source

- `operation`
- `seed`
- `debug`

### validation

- 変更内容は必須
- 発生日時は必須

### 主なメソッド

- `record!`
- `recent`
- `pending_review`
- `pending_count`
- `mark_reviewed!`
- `create_debug!`
- `create_debug_examples!`
- `remove_debug!`
