class CreatePages < ActiveRecord::Migration[5.0]
  def change
    create_table :pages do |t|
      t.string :name
      t.string :object_id
      t.integer :fans
    end
  end
end
