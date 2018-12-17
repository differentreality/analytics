class AddPageReferenceToReactions < ActiveRecord::Migration[5.0]
  def change
    add_column :reactions, :page_id, :integer
  end
end
