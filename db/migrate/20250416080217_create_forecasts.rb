class CreateForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :forecasts do |t|
      t.float :latitude
      t.float :longitude
      t.jsonb :data
      t.datetime :cached_at

      t.timestamps
    end
  end
end
