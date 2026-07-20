class CreateIntegrationFlcs < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_flcs do |t|
      t.references :zoning, null: false, foreign_key: true
      t.string :year, null: false
      t.string :month, null: false
      t.bigint :subscribers_af, null: false, default: 0

      t.timestamps
    end

    add_index :integration_flcs, %i[zoning_id year month], unique: true,
      name: "index_integration_flcs_on_zoning_year_month"
  end
end
