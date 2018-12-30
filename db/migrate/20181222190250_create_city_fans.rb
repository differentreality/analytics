class CreateCityFans < ActiveRecord::Migration[5.0]
  def change
    create_table :city_fans do |t|
      t.text :country
      t.text :municipality
      t.text :province
      t.integer :count
      t.integer :page_id
      t.datetime :date
      t.timestamps
    end
  end
end
