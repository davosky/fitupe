require "rails_helper"

RSpec.describe StatisticSpi::MultipleDelegationsBreakdown do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      # RSSMRA: 2 deleghe (doppia), TTTBRC: 1 sola delega (non conta come multipla)
      create_list(:import_spi, 2, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "TTTBRC70B02H501Z", codice_azzonamento_completo: "GAA01001")
    end

    it "conta solo il pensionato con piu' di una delega, non calcola i comprensori" do
      expect(result.totale.doppia).to eq(1)
      expect(result.totale.tripla).to eq(0)
      expect(result.totale.totale).to eq(1)
      expect(result.comprensori).to be_empty
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:trieste) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    before do
      # RSSMRA: doppia delega, GA e GB (assegnato al primo comprensorio in ordine alfabetico, GA)
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GAA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBB02002")
      # VRDLGU: tripla delega, tutta in GB
      create_list(:import_spi, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "VRDLGU75B02H501Y", codice_azzonamento_completo: "GBC03003")
      # BNCPLA: una sola delega, non conta come multipla
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "BNCPLA60C03H501Z", codice_azzonamento_completo: "GAD04004")
    end

    it "assegna il pensionato con deleghe in piu' comprensori al primo alfabetico" do
      trieste_row = result.comprensori.find { |row| row.zoning == trieste }
      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }

      expect(trieste_row.doppia).to eq(1)
      expect(gorizia_row.tripla).to eq(1)
      expect(gorizia_row.doppia).to eq(0)
    end

    it "il totale regionale resta coerente con la somma dei comprensori" do
      expect(result.totale.doppia).to eq(result.comprensori.sum(&:doppia))
      expect(result.totale.tripla).to eq(result.comprensori.sum(&:tripla))
      expect(result.totale.totale).to eq(result.comprensori.sum(&:totale))
      expect(result.totale.doppia).to eq(1)
      expect(result.totale.tripla).to eq(1)
      expect(result.totale.totale).to eq(2)
    end
  end
end
