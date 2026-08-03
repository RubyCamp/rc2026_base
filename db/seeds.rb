# 固定日付と架空の名称を使い、画面確認に必要な基準データを冪等に投入する。
def upsert_by(model, identity, values = {})
  model.find_or_initialize_by(identity).tap do |record|
    record.assign_attributes(values)
    record.save!
  end
end

cleaning = upsert_by(
  Skill,
  { code: "CLEANING" },
  name: "清掃",
  active: true
)

serving = upsert_by(
  Skill,
  { code: "SERVING" },
  name: "配膳",
  active: true
)

hotel = upsert_by(
  Business,
  { name: "みらいホテル" },
  contact_name: "山田 花子",
  contact_phone: "03-0000-0001",
  active: true
)

hall = upsert_by(
  Business,
  { name: "あおぞら会館" },
  contact_name: "佐藤 太郎",
  contact_phone: "03-0000-0002",
  active: true
)

staff = {
  cleaning: upsert_by(
    StaffMember,
    { name: "清水 さくら" },
    employment_status: :active
  ),

  serving: upsert_by(
    StaffMember,
    { name: "給田 みのり" },
    employment_status: :active
  ),

  unavailable: upsert_by(
    StaffMember,
    { name: "休田 やすみ" },
    employment_status: :active
  ),

  inactive: upsert_by(
    StaffMember,
    { name: "卒業 太郎" },
    employment_status: :inactive
  )
}

[
  [ staff[:cleaning], cleaning, "経験あり" ],
  [ staff[:serving], serving, "経験あり" ],
  [ staff[:unavailable], cleaning, "研修済み" ]
].each do |staff_member, skill, proficiency_label|
  upsert_by(
    StaffSkill,
    { staff_member: staff_member, skill: skill },
    proficiency_label: proficiency_label
  )
end

available_from = Time.zone.local(2026, 8, 20, 9)
available_until = Time.zone.local(2026, 8, 20, 18)

availabilities = staff.to_h do |key, staff_member|
  status =
    staff_member == staff[:unavailable] ? :unavailable : :available

  availability = upsert_by(
    Availability,
    {
      staff_member: staff_member,
      starts_at: available_from
    },
    ends_at: available_until,
    status: status
  )

  [ key, availability ]
end

def upsert_work_request(
  business:,
  required_skill:,
  title:,
  **values
)
  upsert_by(
    WorkRequest,
    {
      business: business,
      title: title
    },
    values.merge(required_skill: required_skill)
  )
end

requests = {
  normal: upsert_work_request(
    business: hotel,
    required_skill: cleaning,
    title: "客室清掃",
    starts_at: Time.zone.local(2026, 8, 20, 10),
    ends_at: Time.zone.local(2026, 8, 20, 12),
    required_staff_count: 1,
    status: :open
  ),

  shortage: upsert_work_request(
    business: hotel,
    required_skill: cleaning,
    title: "宴会場清掃",
    starts_at: Time.zone.local(2026, 8, 20, 13),
    ends_at: Time.zone.local(2026, 8, 20, 15),
    required_staff_count: 3,
    status: :open
  ),

  unavailable: upsert_work_request(
    business: hall,
    required_skill: cleaning,
    title: "午前会場清掃",
    starts_at: Time.zone.local(2026, 8, 20, 10),
    ends_at: Time.zone.local(2026, 8, 20, 12),
    required_staff_count: 1,
    status: :open
  ),

  skill_shortage: upsert_work_request(
    business: hall,
    required_skill: serving,
    title: "式典配膳",
    starts_at: Time.zone.local(2026, 8, 20, 15),
    ends_at: Time.zone.local(2026, 8, 20, 17),
    required_staff_count: 2,
    status: :open
  ),

  overlap: upsert_work_request(
    business: hotel,
    required_skill: cleaning,
    title: "共用部清掃",
    starts_at: Time.zone.local(2026, 8, 20, 11),
    ends_at: Time.zone.local(2026, 8, 20, 13),
    required_staff_count: 1,
    status: :open
  )
}

assignments = {}

[
  [ :normal, :cleaning, :draft ],
  [ :unavailable, :unavailable, :draft ],
  [ :skill_shortage, :cleaning, :draft ],
  [ :overlap, :cleaning, :confirmed ]
].each do |request_key, staff_key, status|
  assignments[request_key] = upsert_by(
    Assignment,
    {
      work_request: requests.fetch(request_key),
      staff_member: staff.fetch(staff_key)
    },
    status: status
  )
end

seed_events = [
  [
    :work_request,
    requests[:normal].id,
    :created,
    "勤務依頼「客室清掃」を登録しました",
    Time.zone.local(2026, 7, 22, 9, 0)
  ],
  [
    :work_request,
    requests[:shortage].id,
    :updated,
    "勤務依頼「宴会場清掃」の必要人数を更新しました",
    Time.zone.local(2026, 7, 22, 9, 15)
  ],
  [
    :availability,
    availabilities[:unavailable].id,
    :updated,
    "休田 やすみさんの勤務可否を更新しました",
    Time.zone.local(2026, 7, 22, 9, 30)
  ],
  [
    :assignment,
    assignments[:skill_shortage].id,
    :assigned,
    "清水 さくらさんを勤務依頼「式典配膳」へ仮割当しました",
    Time.zone.local(2026, 7, 22, 9, 45)
  ],
  [
    :assignment,
    assignments[:overlap].id,
    :confirmed,
    "清水 さくらさんの勤務依頼「共用部清掃」への割当を確定しました",
    Time.zone.local(2026, 7, 22, 10, 0)
  ]
]

seed_events.each_with_index do |event, index|
  target_type,
    target_id,
    action_type,
    summary,
    occurred_at = event

  review_status =
    index == seed_events.length - 1 ? :reviewed : :pending

  upsert_by(
    ChangeEvent,
    {
      source: :seed,
      summary: summary
    },
    target_type: target_type,
    target_id: target_id,
    action_type: action_type,
    occurred_at: occurred_at,
    review_status: review_status,
    reviewed_at:
      review_status == :reviewed ? occurred_at + 30.minutes : nil
  )
end

puts(
  "基準データを投入しました" \
  "（スタッフ#{StaffMember.count}名、" \
  "依頼#{WorkRequest.count}件、" \
  "変更記録#{ChangeEvent.count}件）"
)
