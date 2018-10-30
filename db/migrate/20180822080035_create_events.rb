class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :name
      t.string :object_id
      t.integer :shares
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :posted_at
      t.references :page

      t.timestamps
    end
  end
end
