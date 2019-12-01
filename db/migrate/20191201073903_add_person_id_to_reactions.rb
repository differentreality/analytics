class AddPersonIdToReactions < ActiveRecord::Migration[5.0]
  def change
    add_column :reactions, :person_id, :integer
  end
end
