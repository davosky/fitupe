class CreateZonings < ActiveRecord::Migration[8.1]
  def change
    create_table :zonings do |t|
      t.string :codice_azzonamento, null: false
      t.string :descrizione_azzonamento, null: false

      t.timestamps
    end

    add_index :zonings, :codice_azzonamento, unique: true
  end
end
