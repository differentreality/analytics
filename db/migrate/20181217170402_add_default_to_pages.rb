class AddDefaultToPages < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :default, :boolean, default: false
  end
end
