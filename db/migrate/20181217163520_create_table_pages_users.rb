class CreateTablePagesUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :pages_users do |t|
      t.integer :page_id
      t.integer :user_id
      t.string :access_token

      t.timestamps
    end
  end
end
