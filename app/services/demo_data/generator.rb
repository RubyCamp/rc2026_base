require "set"

module DemoData
  class Generator
    BUSINESS_NAMES = %w[
      青葉ホテル
      みなと旅館
      さくら会館
      ひかりリゾート
      山吹コンベンション
      こもれび温泉
      つばき迎賓館
      風見鶏ホール
      なごみホテル
      水明館
      みどり研修センター
      あかねイベントサービス
    ].freeze

    FAMILY_NAMES = %w[
      佐藤 鈴木 高橋 田中 伊藤 渡辺 山本 中村 小林 加藤 吉田 山田
      佐々木 山口 松本 井上 木村 林 斎藤 清水 山崎 森 池田 橋本
      阿部 石川 前田 藤田 後藤 岡田 長谷川 村上 近藤 石井 坂本
      遠藤 青木 藤井 西村 福田 太田 三浦 藤原 岡本 松田 中川
    ].freeze

    GIVEN_NAMES = %w[
      陽菜 蓮 葵 結衣 湊 美咲 大翔 さくら 拓真 莉子 悠真 花 響
      七海 直樹 杏奈 陽向 真央 健太 和奏 颯太 彩乃 智也 愛理 翔
      菜月 恒一 里奈 恒一 美月 颯 由佳 恒一 千尋 陸 奈緒 樹
      真由 美穂 恒一 遼子 恒一 夏希 恒一
    ].freeze

    SKILLS = [
      [ "CLEANING", "清掃" ],
      [ "SERVING", "配膳" ],
      [ "RECEPTION", "受付" ],
      [ "COOKING", "調理補助" ],
      [ "BED_MAKING", "ベッドメイク" ],
      [ "EVENT_SETUP", "会場設営" ],
      [ "DRIVER", "送迎" ],
      [ "SAFETY", "安全管理" ],
      [ "CHILDCARE", "託児補助" ],
      [ "WAREHOUSE", "備品管理" ],
      [ "FIRST_AID", "救護" ],
      [ "LANGUAGE", "外国語対応" ]
    ].freeze

    JOBS = %w[
      客室清掃 宴会場清掃 共用部清掃 朝食会場準備 式典配膳 受付対応
      会場設営 撤収作業 送迎補助 備品搬入 調理補助 案内スタッフ
      ベッドメイク クローク対応 セミナー運営
    ].freeze

    LOCATIONS = %w[
      正面玄関 南エントランス 宴会場A 宴会場B 研修棟1階 駅前ロータリー
      搬入口 西館ロビー 中庭受付
    ].freeze

    TRANSPORTS = %w[電車 バス 自転車 徒歩 自家用車 送迎車].freeze
    PROFICIENCY_LABELS = %w[初級 経験あり 研修済み 熟練].freeze

    def initialize(seed: nil, label: nil)
      @seed = normalize_seed(seed)
      @random = Random.new(@seed)
      @label = label.presence || "ランダムデモデータ"
      @today = Time.zone.today
      @businesses = []
      @skills = []
      @staff_members = []
      @work_requests = []
      @availabilities = []
      @assignments = []
      @used_names = Set.new
    end

    def call
      ApplicationRecord.transaction { call_without_lock }
    end

    def call_without_lock
      @batch = DemoDataBatch.create!(
        identifier: "demo-#{@seed}-#{Time.current.to_i}-#{SecureRandom.hex(3)}",
        label: @label,
        seed: @seed
      )

      create_skills
      create_businesses
      create_staff_members
      create_staff_skills
      create_availabilities
      create_special_work_requests
      create_random_work_requests
      create_assignments
      create_additional_change_events

      @batch
    end

    private

    def normalize_seed(seed)
      value = seed.presence&.to_i
      value = Random.new_seed if value.nil? || value.zero?
      value.abs % 2_147_000_000
    end

    def create_skills
      count = @random.rand(8..12)

      SKILLS.first(count).each_with_index do |(code, name), index|
        @skills << create_record(
          Skill,
          code: "DEMO_#{code}_#{@seed}_#{index + 1}",
          name: name,
          active: true
        )
      end
    end

    def create_businesses
      count = @random.rand(8..12)

      BUSINESS_NAMES.first(count).each_with_index do |name, index|
        @businesses << create_record(
          Business,
          name: "#{name}（デモ#{index + 1}）",
          contact_name: "#{FAMILY_NAMES[index]} #{GIVEN_NAMES[index]}",
          contact_phone: format("03-%04d-%04d", 1000 + index, 2000 + index),
          active: true,
          notes: "デモ生成データ／交通案内: #{TRANSPORTS[index % TRANSPORTS.length]}"
        )
      end
    end

    def create_staff_members
      count = @random.rand(30..45)
      family_names = FAMILY_NAMES.shuffle(random: @random)
      given_names = GIVEN_NAMES.shuffle(random: @random)

      count.times do |index|
        name = unique_staff_name(family_names[index % family_names.length], given_names[index % given_names.length])
        employment_status = index >= count - 3 ? :inactive : :active

        @staff_members << create_record(
          StaffMember,
          name: name,
          employment_status: employment_status,
          notes: "交通手段: #{TRANSPORTS.sample(random: @random)}／連絡メモ: #{index.even? ? '前日確認' : '当日確認'}"
        )
      end
    end

    def create_staff_skills
      @staff_members.each_with_index do |staff_member, index|
        skill_indexes = if index == 0
          [ 0, 1, 2 ]
        elsif index == 1
          [ 0, 2 ]
        elsif index == 2
          [ 0 ]
        else
          pool = (0...@skills.length).to_a
          pool.shuffle(random: @random).first(@random.rand(2..[ 4, @skills.length ].min))
        end

        skill_indexes.uniq.each do |skill_index|
          next unless (skill = @skills[skill_index])

          create_record(
            StaffSkill,
            staff_member: staff_member,
            skill: skill,
            proficiency_label: PROFICIENCY_LABELS.sample(random: @random)
          )
        end
      end
    end

    def create_availabilities
      special_staff = @staff_members.first(5)
      date_range = (-2..10).to_a.map { |offset| @today + offset.days }

      @staff_members.each_with_index do |staff_member, staff_index|
        date_range.each do |date|
          next if date == @today && special_staff.include?(staff_member)
          next unless @random.rand < 0.58

          availability_shape = @random.rand
          if availability_shape < 0.16
            add_availability(staff_member, date, 7, 19, :unavailable, "希望休／#{TRANSPORTS.sample(random: @random)}")
          elsif availability_shape < 0.29
            add_availability(staff_member, date, 7, 10, :available, "午前のみ／交通: #{TRANSPORTS.sample(random: @random)}")
            add_availability(staff_member, date, 14, 19, :available, "午後のみ／交通: #{TRANSPORTS.sample(random: @random)}")
          else
            start_hour = @random.rand(6..9)
            end_hour = @random.rand(17..21)
            add_availability(staff_member, date, start_hour, end_hour, :available, "終日可／交通: #{TRANSPORTS.sample(random: @random)}")
          end
        end
      end

      add_availability(special_staff[0], @today, 8, 20, :available, "評価用: 必要時間をカバー／電車")
      add_availability(special_staff[1], @today, 8, 20, :available, "重複評価用／バス")
      add_availability(special_staff[2], @today, 8, 20, :available, "スキル不足評価用／徒歩")
      add_availability(special_staff[3], @today, 8, 20, :unavailable, "希望休／自家用車")
      add_availability(special_staff[4], @today, 7, 10, :available, "時間帯の空きあり／自転車")
    end

    def add_availability(staff_member, date, start_hour, end_hour, status, notes)
      availability = create_record(
        Availability,
        staff_member: staff_member,
        starts_at: Time.zone.local(date.year, date.month, date.day, start_hour),
        ends_at: Time.zone.local(date.year, date.month, date.day, end_hour),
        status: status,
        notes: notes
      )

      @availabilities << availability
      record_change(
        target_type: :availability,
        target_id: availability.id,
        action_type: :created,
        summary: "#{staff_member.name}さんの勤務可否を登録しました",
        occurred_at: availability.created_at - @random.rand(1..4).days,
        reviewed: @random.rand < 0.35
      ) if @random.rand < 0.55

      availability
    end

    def create_special_work_requests
      staff = @staff_members
      skill = @skills

      @scenario_requests = {}
      @scenario_requests[:ok] = add_work_request(
        business: @businesses[0],
        required_skill: skill[0],
        title: "評価OK・確定候補",
        date: @today,
        start_hour: 9,
        duration: 2,
        required_staff_count: 1,
        status: :open,
        notes: "評価用：スキル・勤務可能時間ともに問題なし／集合: #{LOCATIONS.sample(random: @random)}"
      )
      @scenario_requests[:overlap_base] = add_work_request(
        business: @businesses[1],
        required_skill: skill[0],
        title: "時間重複・既存シフト",
        date: @today,
        start_hour: 9,
        duration: 2,
        required_staff_count: 1,
        status: :open,
        notes: "時間重複確認用／交通: #{TRANSPORTS.sample(random: @random)}"
      )
      @scenario_requests[:overlap] = add_work_request(
        business: @businesses[2],
        required_skill: skill[0],
        title: "時間重複・評価注意",
        date: @today,
        start_hour: 10,
        duration: 2,
        required_staff_count: 1,
        status: :open,
        notes: "評価用：別の依頼と時間が重なります"
      )
      @scenario_requests[:skill_missing] = add_work_request(
        business: @businesses[3],
        required_skill: skill[1],
        title: "スキル不足・評価注意",
        date: @today,
        start_hour: 13,
        duration: 2,
        required_staff_count: 1,
        status: :open,
        notes: "評価用：必要スキルとスタッフスキルが不一致"
      )
      @scenario_requests[:shortage] = add_work_request(
        business: @businesses[4],
        required_skill: skill[0],
        title: "人員不足・候補確認",
        date: @today,
        start_hour: 16,
        duration: 2,
        required_staff_count: 3,
        status: :open,
        notes: "評価用：必要人数3名／候補を確認してください"
      )
      @scenario_requests[:confirmed] = add_work_request(
        business: @businesses[5],
        required_skill: skill[2] || skill[0],
        title: "確定済み・シフト確認",
        date: @today + 2.days,
        start_hour: 11,
        duration: 3,
        required_staff_count: 1,
        status: :open,
        notes: "シフト表確認用／集合: #{LOCATIONS.sample(random: @random)}"
      )
      @scenario_requests[:cancelled] = add_work_request(
        business: @businesses[6],
        required_skill: skill[3] || skill[0],
        title: "過去・取消済み依頼",
        date: @today - 7.days,
        start_hour: 10,
        duration: 2,
        required_staff_count: 2,
        status: :cancelled,
        notes: "過去データ確認用"
      )

      # Guarantee the key evaluation records have the intended staffing state.
      create_direct_assignment(@scenario_requests[:ok], staff[0], :draft)
      create_direct_assignment(@scenario_requests[:overlap_base], staff[1], :confirmed)
      create_direct_assignment(@scenario_requests[:overlap], staff[1], :draft)
      create_direct_assignment(@scenario_requests[:skill_missing], staff[2], :draft)
      create_direct_assignment(@scenario_requests[:shortage], staff[4], :draft)
      create_direct_assignment(@scenario_requests[:confirmed], staff[0], :confirmed)

      record_change(
        target_type: :work_request,
        target_id: @scenario_requests[:ok].id,
        action_type: :updated,
        summary: "評価用の勤務依頼を確認待ちにしました",
        occurred_at: Time.current - 2.hours,
        reviewed: false
      )
      record_change(
        target_type: :work_request,
        target_id: @scenario_requests[:confirmed].id,
        action_type: :updated,
        summary: "確定済み勤務依頼の変更を確認しました",
        occurred_at: Time.current - 1.hour,
        reviewed: true
      )
    end

    def create_random_work_requests
      count = @random.rand(35..60) - @scenario_requests.length
      base_offsets = (-14..30).to_a

      count.times do |index|
        date = @today + base_offsets.sample(random: @random).days
        start_hour = @random.rand(6..18)
        duration = @random.rand(1..4)
        status = random_request_status(date)

        add_work_request(
          business: @businesses.sample(random: @random),
          required_skill: @skills.sample(random: @random),
          title: "#{JOBS.sample(random: @random)} #{index + 1}",
          date: date,
          start_hour: start_hour,
          duration: duration,
          required_staff_count: @random.rand(1..4),
          status: status,
          notes: "集合: #{LOCATIONS.sample(random: @random)}／交通: #{TRANSPORTS.sample(random: @random)}"
        )
      end
    end

    def random_request_status(date)
      return :cancelled if date < @today - 5.days && @random.rand < 0.15
      return :confirmed if date < @today && @random.rand < 0.2
      return :draft if @random.rand < 0.25

      :open
    end

    def add_work_request(business:, required_skill:, title:, date:, start_hour:, duration:, required_staff_count:, status:, notes:)
      starts_at = Time.zone.local(date.year, date.month, date.day, start_hour)
      work_request = create_record(
        WorkRequest,
        business: business,
        required_skill: required_skill,
        title: title,
        starts_at: starts_at,
        ends_at: starts_at + duration.hours,
        required_staff_count: required_staff_count,
        status: status,
        notes: notes
      )
      @work_requests << work_request

      record_change(
        target_type: :work_request,
        target_id: work_request.id,
        action_type: :created,
        summary: "勤務依頼「#{work_request.title}」を登録しました",
        occurred_at: work_request.created_at - @random.rand(1..6).days,
        reviewed: @random.rand < 0.3
      )

      work_request
    end

    def create_assignments
      candidates = @staff_members.select(&:active?)

      @work_requests.each do |work_request|
        next if @scenario_requests.value?(work_request)
        next if work_request.cancelled? && @random.rand < 0.8

        assignment_count = @random.rand < 0.58 ? [ work_request.required_staff_count, 1 ].max : @random.rand(0..2)
        assignment_count.times do
          staff_member = candidates.sample(random: @random)
          next unless staff_member
          next if Assignment.exists?(work_request_id: work_request.id, staff_member_id: staff_member.id)

          status = work_request.confirmed? || @random.rand < 0.22 ? :confirmed : :draft
          create_direct_assignment(work_request, staff_member, status)
        end
      end
    end

    def create_direct_assignment(work_request, staff_member, status)
      return if Assignment.exists?(work_request_id: work_request.id, staff_member_id: staff_member.id)

      assignment = create_record(
        Assignment,
        work_request: work_request,
        staff_member: staff_member,
        status: status,
        notes: "デモ生成：交通手段 #{staff_member.notes.to_s[/交通手段: ([^／]+)/, 1] || '要確認'}"
      )
      @assignments << assignment

      record_change(
        target_type: :assignment,
        target_id: assignment.id,
        action_type: :assigned,
        summary: "#{staff_member.name}さんを勤務依頼「#{work_request.title}」へ仮割当しました",
        occurred_at: assignment.created_at - @random.rand(1..3).days,
        reviewed: @random.rand < 0.25
      )

      if assignment.confirmed?
        record_change(
          target_type: :assignment,
          target_id: assignment.id,
          action_type: :confirmed,
          summary: "#{staff_member.name}さんの勤務依頼「#{work_request.title}」への割当を確定しました",
          occurred_at: assignment.created_at - @random.rand(0..1).days,
          reviewed: @random.rand < 0.5
        )
      end

      assignment
    end

    def create_additional_change_events
      @work_requests.sample([ 8, @work_requests.length ].min, random: @random).each do |work_request|
        record_change(
          target_type: :work_request,
          target_id: work_request.id,
          action_type: :updated,
          summary: "勤務依頼「#{work_request.title}」の集合場所を更新しました",
          occurred_at: Time.current - @random.rand(1..20).days,
          reviewed: @random.rand < 0.45
        )
      end

      @assignments.sample([ 6, @assignments.length ].min, random: @random).each do |assignment|
        record_change(
          target_type: :assignment,
          target_id: assignment.id,
          action_type: :updated,
          summary: "#{assignment.staff_member.name}さんの割当メモを更新しました",
          occurred_at: Time.current - @random.rand(1..15).days,
          reviewed: @random.rand < 0.5
        )
      end
    end

    def record_change(target_type:, target_id:, action_type:, summary:, occurred_at:, reviewed:)
      record = ChangeEvent.create!(
        target_type: target_type,
        target_id: target_id,
        action_type: action_type,
        summary: summary,
        occurred_at: occurred_at,
        source: :seed,
        review_status: reviewed ? :reviewed : :pending,
        reviewed_at: reviewed ? occurred_at + 30.minutes : nil
      )
      @batch.track!(record)
    end

    def create_record(model, attributes)
      record = model.create!(attributes)
      @batch.track!(record)
      record
    end

    def unique_staff_name(family_name, given_name)
      candidate = "#{family_name} #{given_name}"
      suffix = 2

      while @used_names.include?(candidate)
        candidate = "#{family_name} #{given_name}#{suffix}"
        suffix += 1
      end

      @used_names << candidate
      candidate
    end
  end
end
