class AddUserIdToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :user_id, :integer
  end
end
