class CreateAgeFans < ActiveRecord::Migration[5.0]
  def change
    create_table :age_fans do |t|
      t.integer :gender
      t.integer :age_range
      t.integer :count
      t.datetime :date
      t.integer :page_id
      t.timestamps
    end
  end
end
