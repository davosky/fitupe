class CreateLegends < ActiveRecord::Migration[8.1]
  def change
    create_table :legends do |t|
      t.references :zoning, null: false, foreign_key: true
      t.string :year, null: false
      t.string :month, null: false

      t.timestamps
    end

    add_index :legends, %i[zoning_id year month], unique: true, name: "index_legends_on_zoning_year_month"
  end
end
