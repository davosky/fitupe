require "rails_helper"

RSpec.describe Imports::SchemaSyncService do
  after { Import.reset_column_information }

  it "aggiunge una colonna mancante come string" do
    described_class.call([ "Campo Sperimentale Nuovo" ])

    expect(Import.column_names).to include("campo_sperimentale_nuovo")
  end

  it "aggiunge come date una colonna nuova elencata in DATE_COLUMNS" do
    stub_const("Import::DATE_COLUMNS", Import::DATE_COLUMNS + [ "campo_data_nuovo" ])

    described_class.call([ "Campo Data Nuovo" ])

    column = Import.columns.find { |c| c.name == "campo_data_nuovo" }
    expect(column.sql_type).to eq("date")
  end

  it "non tocca lo schema se le colonne esistono già" do
    described_class.call([ "Cognome" ])

    expect { described_class.call([ "Cognome" ]) }.not_to(change { Import.columns.map(&:name) })
  end

  it "ignora Utente Modifica e Data Modifica" do
    described_class.call([ "Utente Modifica", "Data Modifica" ])

    expect(Import.column_names).not_to include("utente_modifica", "data_modifica")
  end
end
