require "rails_helper"

RSpec.describe StatisticSpi::CessazioniBreakdown do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", motivo_cessazione_iscrizione: "Decesso", codice_azzonamento_completo: "GAA01001")
      create_list(:import_spi, 3, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GAA01001")
    end

    it "conta le cessazioni per motivo sul totale deleghe (attive e cessate), non calcola i comprensori" do
      expect(result.totale.totali["Decesso"]).to eq(1)
      expect(result.totale.totale).to eq(1)
      expect(result.totale.deleghe_totale).to eq(4)
      expect(result.totale.percentuali["Decesso"]).to eq(25.0)
      expect(result.comprensori).to be_empty
    end

    it "esclude i motivi non nell'elenco rilevante" do
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", motivo_cessazione_iscrizione: "Scadenza versamento diretto",
        codice_azzonamento_completo: "GAA01001")

      expect(result.totale.totali.values.sum).to eq(1)
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:trieste) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    before do
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", motivo_cessazione_iscrizione: "Decesso", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", motivo_cessazione_iscrizione: "Revoca", codice_azzonamento_completo: "GBB02002")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GBB02002")
    end

    it "assegna ogni cessazione al comprensorio corretto, categorizzando il motivo" do
      trieste_row = result.comprensori.find { |row| row.zoning == trieste }
      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }

      expect(trieste_row.totali["Decesso"]).to eq(1)
      expect(gorizia_row.totali["Revoca"]).to eq(1)
    end

    it "il totale regionale resta coerente con la somma dei comprensori" do
      StatisticSpi::CessazioniBreakdown::ETICHETTE.each do |etichetta|
        expect(result.totale.totali[etichetta]).to eq(result.comprensori.sum { |row| row.totali[etichetta] })
      end
      expect(result.totale.totale).to eq(result.comprensori.sum(&:totale))
      expect(result.totale.totale).to eq(2)
    end

    it "calcola la percentuale sul totale deleghe di ciascun comprensorio, non sul totale regionale" do
      trieste_row = result.comprensori.find { |row| row.zoning == trieste }

      expect(trieste_row.deleghe_totale).to eq(2)
      expect(trieste_row.percentuali["Decesso"]).to eq(50.0)
      expect(result.totale.deleghe_totale).to eq(4)
      expect(result.totale.percentuali["Decesso"]).to eq(25.0)
    end
  end
end
