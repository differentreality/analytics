class ChangeDateInCityFans < ActiveRecord::Migration[5.0]
  def change
    change_column :city_fans, :date, :date
  end
end
