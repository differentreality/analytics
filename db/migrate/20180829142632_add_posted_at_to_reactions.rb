class AddPostedAtToReactions < ActiveRecord::Migration[5.0]
  def change
    add_column :reactions, :posted_at, :datetime
  end
end
