require "rails_helper"

RSpec.describe Imports::HeaderNormalizer do
  it "normalizza gli header in snake_case" do
    examples = {
      "Codice Fiscale" => "codice_fiscale",
      "Consenso 1 (com dati sensibili)" => "consenso_1_com_dati_sensibili",
      "Nazionalità" => "nazionalita",
      "Localita Postale" => "localita_postale",
      "Utente Modifica" => "utente_modifica",
      "SAP" => "sap"
    }

    examples.each do |header, expected|
      expect(described_class.call(header)).to eq(expected)
    end
  end
end
