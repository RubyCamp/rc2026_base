class CreateBusinesses < ActiveRecord::Migration[8.1]
  def change
    create_table :businesses do |t|
      t.string :name, null: false
      t.string :contact_name, null: false
      t.string :contact_phone, null: false
      t.boolean :active, null: false, default: true
      t.text :notes

      t.timestamps
    end

    add_index :businesses, :name
  end
end
