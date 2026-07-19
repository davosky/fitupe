class CreateIntegrationFilleas < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_filleas do |t|
      t.references :zoning, null: false, foreign_key: true
      t.string :year, null: false
      t.bigint :subscribers_ce, null: false, default: 0

      t.timestamps
    end

    add_index :integration_filleas, %i[zoning_id year], unique: true,
      name: "index_integration_filleas_on_zoning_year"
  end
end
