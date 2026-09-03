class CreateDemoDataTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :demo_data_batches do |t|
      t.string :identifier, null: false
      t.string :label, null: false
      t.bigint :seed, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :demo_data_batches, :identifier, unique: true
    add_index :demo_data_batches, :created_at

    create_table :demo_data_records do |t|
      t.references :demo_data_batch, null: false, foreign_key: { on_delete: :cascade }
      t.string :record_type, null: false
      t.bigint :record_id, null: false

      t.timestamps
    end

    add_index :demo_data_records,
              %i[demo_data_batch_id record_type record_id],
              unique: true,
              name: "index_demo_data_records_on_batch_and_record"
    add_index :demo_data_records,
              %i[record_type record_id],
              unique: true,
              name: "index_demo_data_records_on_record"

    add_check_constraint :demo_data_batches,
                         "status IN ('active', 'cleaned')",
                         name: "demo_data_batches_status_check"

    add_check_constraint :demo_data_records,
                         "record_type IN ('Business', 'Skill', 'StaffMember', 'StaffSkill', 'Availability', 'WorkRequest', 'Assignment', 'ChangeEvent')",
                         name: "demo_data_records_type_check"

    reversible do |direction|
      direction.up do
        execute "ALTER TABLE demo_data_batches ENABLE ROW LEVEL SECURITY"
        execute "ALTER TABLE demo_data_records ENABLE ROW LEVEL SECURITY"

        app_roles = select_values(
          "SELECT rolname FROM pg_roles WHERE rolname = 'rc2026_app'"
        )
        next if app_roles.empty?

        execute <<~SQL
          GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE demo_data_batches, demo_data_records TO rc2026_app;
          GRANT USAGE, SELECT, UPDATE ON SEQUENCE demo_data_batches_id_seq, demo_data_records_id_seq TO rc2026_app;
          CREATE POLICY demo_data_batches_app_access ON demo_data_batches
            FOR ALL TO rc2026_app USING (true) WITH CHECK (true);
          CREATE POLICY demo_data_records_app_access ON demo_data_records
            FOR ALL TO rc2026_app USING (true) WITH CHECK (true);
        SQL
      end
    end

    # The application connects directly with DATABASE_URL. Do not expose the
    # ownership tables through the Supabase Data API's public roles.
    reversible do |direction|
      direction.up do
        data_api_roles = select_values(
          "SELECT rolname FROM pg_roles WHERE rolname IN ('anon', 'authenticated')"
        )
        next if data_api_roles.empty?

        execute <<~SQL
          REVOKE ALL ON TABLE demo_data_batches, demo_data_records FROM #{data_api_roles.join(', ')};
        SQL
      end
    end
  end
end
