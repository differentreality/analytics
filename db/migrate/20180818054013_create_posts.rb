class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.text :message
      t.string :object_id
      t.integer :shares
      t.integer :kind
      t.datetime :posted_at

      t.timestamps
    end
  end
end
