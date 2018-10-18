class RemoveCountInReactions < ActiveRecord::Migration[5.0]
  def change
    remove_column :reactions, :count, :integer
  end
end
