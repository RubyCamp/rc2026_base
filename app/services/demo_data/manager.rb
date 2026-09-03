module DemoData
  class Manager
    TRACKED_TYPES = {
      "Business" => Business,
      "Skill" => Skill,
      "StaffMember" => StaffMember,
      "StaffSkill" => StaffSkill,
      "Availability" => Availability,
      "WorkRequest" => WorkRequest,
      "Assignment" => Assignment,
      "ChangeEvent" => ChangeEvent
    }.freeze

    CLEANUP_ORDER = %w[
      ChangeEvent
      Assignment
      Availability
      WorkRequest
      StaffSkill
      StaffMember
      Skill
      Business
    ].freeze

    class << self
      def summary
        current_counts = TRACKED_TYPES.transform_values(&:count)
        demo_counts = DemoDataRecord.group(:record_type).count

        {
          current: current_counts,
          demo: TRACKED_TYPES.keys.to_h { |type| [ type, demo_counts.fetch(type, 0) ] },
          batches: DemoDataBatch.active.latest_first,
          total_batches: DemoDataBatch.count
        }
      end

      def generate!(seed: nil, label: nil)
        with_lock do
          Generator.new(seed: seed, label: label).call
        end
      end

      def reset!(seed: nil)
        with_lock do
          ApplicationRecord.transaction do
            cleanup_locked!
            Generator.new(seed: seed, label: "基準デモデータ").call_without_lock
          end
        end
      end

      def cleanup!
        with_lock do
          ApplicationRecord.transaction { cleanup_locked! }
        end
      end

      private

      def cleanup_locked!
        owned = DemoDataRecord
          .order(:id)
          .pluck(:id, :demo_data_batch_id, :record_type, :record_id)
          .group_by { |_, _, record_type, _| record_type }

        CLEANUP_ORDER.each do |record_type|
          owned.fetch(record_type, []).each do |ownership_id, _batch_id, _type, record_id|
            deleted = ApplicationRecord.transaction(requires_new: true) do
              TRACKED_TYPES.fetch(record_type).where(id: record_id).delete_all
            end
            next unless deleted == 1

            DemoDataRecord.where(id: ownership_id).delete_all
          rescue ActiveRecord::InvalidForeignKey
            # A manual record may have been added after generation. Preserve
            # the generated parent instead of deleting unrelated data.
            next
          end
        end

        empty_batch_ids = DemoDataBatch
          .where.not(id: DemoDataRecord.select(:demo_data_batch_id))
          .pluck(:id)
        DemoDataBatch.where(id: empty_batch_ids).update_all(status: "cleaned")
        DemoDataBatch.where(id: empty_batch_ids).delete_all
        nil
      end

      def with_lock
        ApplicationRecord.transaction do
          if ApplicationRecord.connection.adapter_name.downcase.include?("postgres")
            ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(2840262026)")
          end

          yield
        end
      end
    end
  end
end
