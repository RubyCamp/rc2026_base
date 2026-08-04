# ER図

共通基盤で使用する主なテーブルと関連を示す。

```mermaid
erDiagram
    businesses ||--o{ work_requests : has
    skills ||--o{ work_requests : required_by

    staff_members ||--o{ availabilities : has

    work_requests ||--o{ assignments : has
    staff_members ||--o{ assignments : assigned

    staff_members ||--o{ staff_skills : has
    skills ||--o{ staff_skills : has

    businesses {
        bigint id PK
        string name
        string contact_name
        string contact_phone
        boolean active
        text notes
    }

    work_requests {
        bigint id PK
        bigint business_id FK
        bigint required_skill_id FK
        string title
        datetime starts_at
        datetime ends_at
        integer required_staff_count
        string status
        text notes
    }

    staff_members {
        bigint id PK
        string name
        string employment_status
        text notes
    }

    availabilities {
        bigint id PK
        bigint staff_member_id FK
        datetime starts_at
        datetime ends_at
        string status
        text notes
    }

    assignments {
        bigint id PK
        bigint work_request_id FK
        bigint staff_member_id FK
        string status
        text notes
    }

    skills {
        bigint id PK
        string code
        string name
        boolean active
    }

    staff_skills {
        bigint id PK
        bigint staff_member_id FK
        bigint skill_id FK
        string proficiency_label
    }

    change_events {
        bigint id PK
        string target_type
        bigint target_id
        string action_type
        string review_status
        string source
        string summary
        datetime occurred_at
        datetime reviewed_at
    }
```

## 主な制約

- `skills.code`は重複不可
- `assignments`では、勤務依頼とスタッフの組み合わせは重複不可
- `staff_skills`では、スタッフとスキルの組み合わせは重複不可
- 勤務依頼は事業者と必要スキルを参照する
- 変更記録の`target_id`は、`target_type`で示された業務データのIDを保存する
