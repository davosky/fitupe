require "rails_helper"

RSpec.describe StatisticSpi::TipologieDelegaBreakdown do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Concomitante", codice_azzonamento_completo: "GAA01001")
    end

    it "conta le deleghe per tipologia, non calcola i comprensori" do
      expect(result.totale.totali["Ordinaria"]).to eq(1)
      expect(result.totale.totali["Concomitante"]).to eq(1)
      expect(result.totale.totale).to eq(2)
      expect(result.comprensori).to be_empty
    end

    it "calcola la percentuale sul totale deleghe, non sugli iscritti" do
      expect(result.totale.percentuali["Ordinaria"]).to eq(50.0)
      expect(result.totale.percentuali["Concomitante"]).to eq(50.0)
      expect(result.totale.percentuali["Altro"]).to eq(0.0)
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:trieste) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    before do
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Concomitante", codice_azzonamento_completo: "GBB02002")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Invalidi civili", codice_azzonamento_completo: "GBB02002")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Pagamento Diretto (Brevi Manu)",
        codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_delega: "Reversibilità", codice_azzonamento_completo: "GBB02002")
    end

    it "assegna ogni delega al comprensorio corretto, categorizzando la tipologia" do
      trieste_row = result.comprensori.find { |row| row.zoning == trieste }
      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }

      expect(trieste_row.totali["Ordinaria"]).to eq(1)
      expect(trieste_row.totali["BreviManu"]).to eq(1)
      expect(gorizia_row.totali["Concomitante"]).to eq(1)
      expect(gorizia_row.totali["Invalidi Civili"]).to eq(1)
      expect(gorizia_row.totali["Altro"]).to eq(1)
    end

    it "il totale regionale resta coerente con la somma dei comprensori" do
      StatisticSpi::TipologieDelegaBreakdown::ETICHETTE.each do |etichetta|
        expect(result.totale.totali[etichetta]).to eq(result.comprensori.sum { |row| row.totali[etichetta] })
      end
      expect(result.totale.totale).to eq(result.comprensori.sum(&:totale))
      expect(result.totale.totale).to eq(5)
    end

    it "non calcola alcuna percentuale per un comprensorio senza deleghe" do
      pordenone_row = result.comprensori.find { |row| row.zoning == pordenone }

      expect(pordenone_row.totale).to eq(0)
      expect(pordenone_row.percentuali.values).to all(be_nil)
    end
  end
end
