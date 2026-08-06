require "rails_helper"

RSpec.describe StatisticSpi::ProvvisorieBreakdown do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", provvisoria: "SI", codice_azzonamento_completo: "GAA01001")
      create_list(:import_spi, 3, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", provvisoria: "NO", codice_azzonamento_completo: "GAA01001")
    end

    it "conta le provvisorie sul totale deleghe, non calcola i comprensori" do
      expect(result.totale.totale).to eq(1)
      expect(result.totale.deleghe_totale).to eq(4)
      expect(result.totale.percentuale).to eq(25.0)
      expect(result.comprensori).to be_empty
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:trieste) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    before do
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", provvisoria: "SI", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", provvisoria: "NO", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", provvisoria: "SI", codice_azzonamento_completo: "GBB02002")
      create_list(:import_spi, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", provvisoria: "NO", codice_azzonamento_completo: "GBB02002")
    end

    it "assegna ogni provvisoria al comprensorio corretto" do
      trieste_row = result.comprensori.find { |row| row.zoning == trieste }
      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }

      expect(trieste_row.totale).to eq(1)
      expect(gorizia_row.totale).to eq(1)
    end

    it "il totale regionale resta coerente con la somma dei comprensori" do
      expect(result.totale.totale).to eq(result.comprensori.sum(&:totale))
      expect(result.totale.totale).to eq(2)
    end

    it "calcola la percentuale sul totale deleghe di ciascun comprensorio, non sul totale regionale" do
      trieste_row = result.comprensori.find { |row| row.zoning == trieste }
      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }

      expect(trieste_row.deleghe_totale).to eq(2)
      expect(trieste_row.percentuale).to eq(50.0)
      expect(gorizia_row.deleghe_totale).to eq(4)
      expect(gorizia_row.percentuale).to eq(25.0)
      expect(result.totale.deleghe_totale).to eq(6)
      expect(result.totale.percentuale).to be_within(0.01).of(33.33)
    end
  end
end
