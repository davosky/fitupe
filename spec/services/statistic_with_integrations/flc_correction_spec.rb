require "rails_helper"

RSpec.describe StatisticWithIntegrations::FlcCorrection do
  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando l'azzonamento scelto non è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GD", descrizione_azzonamento: "Udine") }

    context "quando esiste il dato Anagrafe FLC del mese precedente" do
      before do
        create(:integration_flc, zoning: zoning, year: "2026", month: "Maggio", subscribers_af: 102)
      end

      it "somma il dato Anagrafe FLC del mese precedente (non lo confronta con SinCGIL)" do
        expect(result).to be_success
        expect(result.rows.size).to eq(1)

        riga = result.rows.first
        expect(riga.zoning).to eq(zoning)
        expect(riga.anagrafe).to eq(102)
        expect(riga.diff).to eq(102)
        expect(result.total_diff).to eq(102)
      end
    end

    it "ignora un eventuale dato dello stesso mese (serve quello del mese precedente)" do
      create(:integration_flc, zoning: zoning, year: "2026", month: "Giugno", subscribers_af: 999)

      expect(result).not_to be_success
    end

    context "quando manca il dato del mese precedente" do
      it "fallisce con un messaggio esplicativo" do
        expect(result).not_to be_success
        expect(result.error).to match(/Udine/)
        expect(result.error).to match(/Maggio/)
      end
    end

    context "quando il mese scelto è Gennaio" do
      subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Gennaio") }

      it "cerca il dato di Dicembre dell'anno precedente" do
        create(:integration_flc, zoning: zoning, year: "2025", month: "Dicembre", subscribers_af: 77)

        expect(result).to be_success
        expect(result.rows.first.anagrafe).to eq(77)
      end
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    context "quando tutte le province hanno il dato Anagrafe FLC del mese precedente" do
      before do
        create(:integration_flc, zoning: gorizia, year: "2026", month: "Maggio", subscribers_af: 73)
        create(:integration_flc, zoning: pordenone, year: "2026", month: "Maggio", subscribers_af: 108)
      end

      it "calcola una riga per ciascuna provincia e la somma totale" do
        expect(result).to be_success
        expect(result.rows.map { |row| row.zoning.codice_azzonamento }).to eq(%w[GB GC])
        expect(result.rows.sum(&:anagrafe)).to eq(181)
        expect(result.total_diff).to eq(181)
      end
    end

    context "quando una provincia non ha il dato Anagrafe FLC del mese precedente" do
      before do
        create(:integration_flc, zoning: gorizia, year: "2026", month: "Maggio", subscribers_af: 73)
      end

      it "non si blocca, integra solo le province con il dato disponibile" do
        expect(result).to be_success
        expect(result.rows.map { |row| row.zoning }).to eq([ gorizia ])
        expect(result.total_diff).to eq(73)
      end
    end

    context "quando nessuna provincia ha il dato Anagrafe FLC del mese precedente" do
      it "non si blocca e non applica alcuna correzione" do
        expect(result).to be_success
        expect(result.rows).to be_empty
        expect(result.total_diff).to eq(0)
      end
    end
  end
end
