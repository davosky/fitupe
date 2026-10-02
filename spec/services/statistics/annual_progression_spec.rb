require "rails_helper"

RSpec.describe Statistics::AnnualProgression do
  let(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "Friuli Venezia Giulia") }
  let!(:trieste) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }

  subject(:result) { described_class.call(zoning: regione, anno: "2026") }

  def iscritti(count, anno, mese)
    create_list(:import, count, azzonamento_di_riferimento: regione, anno_di_riferimento: anno,
      mese_di_riferimento: mese, codice_azzonamento_completo: "GA01")
  end

  context "quando mancano i dati dell'anno scelto" do
    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2026/)
    end
  end

  context "quando mancano i dati dell'anno precedente" do
    before { iscritti(2, "2026", "Gennaio") }

    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2025/)
    end
  end

  context "quando esistono dati per entrambi gli anni" do
    before do
      iscritti(4, "2025", "Gennaio")
      iscritti(5, "2025", "Febbraio")
      iscritti(9, "2025", "Marzo")
      iscritti(2, "2026", "Gennaio")
      iscritti(3, "2026", "Marzo")
    end

    it "limita i mesi all'ultimo disponibile dell'anno scelto" do
      expect(result.mesi).to eq(%w[Gennaio Febbraio Marzo])
      expect(result.rows_anno.first.counts).to eq([ 2, 0, 3 ])
    end

    it "include una riga per la regione e per ogni comprensorio" do
      expect(result.rows_precedente.map(&:zoning)).to eq([ regione, trieste ])
    end

    it "calcola la crescita % da Gennaio all'ultimo mese e la differenza tra gli anni" do
      gap = result.gaps.sole
      expect(gap.zoning).to eq(trieste)
      expect(gap.crescita_precedente).to be_within(0.01).of(125.0)
      expect(gap.crescita_anno).to be_within(0.01).of(50.0)
      expect(gap.differenza).to be_within(0.01).of(-75.0)
    end

    context "con le integrazioni FILLEA e FLC" do
      before do
        create(:integration_flc, zoning: trieste, year: "2026", month: "Marzo", subscribers_af: 3)
        create(:integration_fillea, zoning: trieste, year: "2025", subscribers_ce: 1)
      end

      it "ricalibra i conteggi dei comprensori e della regione" do
        expect(result.rows_anno.map(&:counts)).to all(eq([ 2, 0, 6 ]))
        expect(result.rows_precedente.map(&:counts)).to all(eq([ 5, 6, 10 ]))
        expect(result.gaps.sole.crescita_anno).to be_within(0.01).of(200.0)
      end
    end
  end
end
