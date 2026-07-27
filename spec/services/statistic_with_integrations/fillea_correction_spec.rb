require "rails_helper"

RSpec.describe StatisticWithIntegrations::FilleaCorrection do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    context "quando esiste il dato Cassa Edile per l'anno" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 402)
        create_list(:import, 128, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria Cassa Edile")
        create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria")
      end

      it "calcola la differenza fra Cassa Edile e il conteggio SinCGIL Ordinaria Cassa Edile" do
        expect(result).to be_success
        expect(result.rows.size).to eq(1)

        riga = result.rows.first
        expect(riga.zoning).to eq(zoning)
        expect(riga.cassa_edile).to eq(402)
        expect(riga.sincgil).to eq(128)
        expect(riga.diff).to eq(274)
        expect(result.total_diff).to eq(274)
      end
    end

    context "quando il conteggio SinCGIL supera quello Cassa Edile" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 545)
        create_list(:import, 572, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria Cassa Edile")
      end

      it "restituisce una differenza negativa" do
        expect(result).to be_success
        expect(result.rows.first.diff).to eq(-27)
        expect(result.total_diff).to eq(-27)
      end
    end

    context "quando manca il dato Cassa Edile per l'anno scelto" do
      it "fallisce con un messaggio esplicativo" do
        expect(result).not_to be_success
        expect(result.error).to match(/Gorizia/)
        expect(result.error).to match(/2026/)
      end
    end

    it "non conta gli iscritti di un altro mese" do
      create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 10)
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Luglio", tipologia_delega: "Ordinaria Cassa Edile")

      expect(result.rows.first.sincgil).to eq(0)
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    context "quando tutte le province hanno il dato Cassa Edile" do
      before do
        create(:integration_fillea, zoning: gorizia, year: "2026", subscribers_ce: 402)
        create(:integration_fillea, zoning: pordenone, year: "2026", subscribers_ce: 545)
        create_list(:import, 128, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria Cassa Edile",
          codice_azzonamento_completo: "GB001")
        create_list(:import, 572, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria Cassa Edile",
          codice_azzonamento_completo: "GC001")
      end

      it "calcola una riga per ciascuna provincia e la somma totale" do
        expect(result).to be_success
        expect(result.rows.map { |row| row.zoning.codice_azzonamento }).to eq(%w[GB GC])

        gorizia_row = result.rows.find { |row| row.zoning == gorizia }
        expect(gorizia_row.diff).to eq(274)

        pordenone_row = result.rows.find { |row| row.zoning == pordenone }
        expect(pordenone_row.diff).to eq(-27)

        expect(result.total_diff).to eq(247)
      end
    end

    context "quando una provincia non ha il dato Cassa Edile" do
      before do
        create(:integration_fillea, zoning: gorizia, year: "2026", subscribers_ce: 402)
      end

      it "fallisce con un messaggio che indica la provincia mancante" do
        expect(result).not_to be_success
        expect(result.error).to match(/Pordenone/)
      end
    end
  end
end
