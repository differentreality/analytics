class CreateReactions < ActiveRecord::Migration[5.0]
  def change
    create_table :reactions do |t|
      t.references :reactionable, polymorphic: true
      t.string :name
      t.integer :count

      t.timestamps
    end
  end
end
