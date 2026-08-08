require "rails_helper"

RSpec.describe StatisticSpi::AgeBreakdown do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      # Stesso codice fiscale, due deleghe (reversibilita'): va contato una sola volta.
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GAA01001",
        data_nascita: 65.years.ago.to_date)
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GAA01001",
        data_nascita: 65.years.ago.to_date)
    end

    it "conta l'iscritto una sola volta nella fascia corrispondente, non calcola i comprensori" do
      expect(result.totale.totali["SESSANTENNI"]).to eq(1)
      expect(result.totale.totale).to eq(1)
      expect(result.comprensori).to be_empty
    end
  end

  context "quando la data di nascita e' assente" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GAA01001", data_nascita: nil)
    end

    it "non lo conta in nessuna fascia" do
      expect(result.totale.totale).to eq(0)
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    before do
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "AAAAAA00A01H501A", codice_azzonamento_completo: "GBA01001", data_nascita: 55.years.ago.to_date)
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "BBBBBB00A01H501B", codice_azzonamento_completo: "GCC03003", data_nascita: 75.years.ago.to_date)
    end

    it "aggiunge una riga per ciascun comprensorio e il totale resta coerente con la somma" do
      expect(result.comprensori.map { |row| row.zoning.codice_azzonamento }).to eq(%w[GB GC])

      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }
      expect(gorizia_row.totali["CINQUANTENNI"]).to eq(1)

      pordenone_row = result.comprensori.find { |row| row.zoning == pordenone }
      expect(pordenone_row.totali["SETTANTENNI"]).to eq(1)

      expect(result.totale.totale).to eq(result.comprensori.sum(&:totale))
      expect(result.totale.percentuali["CINQUANTENNI"]).to be_within(0.01).of(50.0)
    end
  end
end
