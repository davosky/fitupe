require "rails_helper"

RSpec.describe Statistics::AnnualCategoryProgression do
  let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }

  subject(:result) { described_class.call(zoning:, anno: "2026") }

  def iscritti(count, anno, mese, **categoria)
    create_list(:import, count, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
      mese_di_riferimento: mese, **categoria)
  end

  context "quando mancano i dati dell'anno precedente" do
    before { iscritti(1, "2026", "Gennaio", categoria: "FIOM") }

    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2025/)
    end
  end

  context "quando esistono dati per entrambi gli anni" do
    before do
      iscritti(2, "2025", "Gennaio", categoria: "FIOM")
      iscritti(3, "2025", "Febbraio", categoria_sindacale: "FIOM")
      iscritti(1, "2025", "Febbraio", categoria_sindacale: "FILLEA")
      iscritti(4, "2026", "Gennaio", categoria: "FIOM")
      iscritti(2, "2026", "Gennaio", categoria: "FILLEA")
      iscritti(5, "2026", "Febbraio", categoria_sindacale: "FIOM")
      iscritti(2, "2026", "Febbraio", categoria_sindacale: "FILLEA")
    end

    it "una riga per categoria, unendo mesi importati con Categoria e con Categoria Sindacale" do
      expect(result.rows_anno.map(&:label)).to eq(%w[FILLEA FIOM])
      expect(result.rows_anno.map(&:counts)).to eq([ [ 2, 2 ], [ 4, 5 ] ])
      expect(result.rows_precedente.map(&:counts)).to eq([ [ 0, 1 ], [ 2, 3 ] ])
    end

    it "calcola crescita e differenza per categoria" do
      fiom = result.gaps.find { |gap| gap.categoria == "FIOM" }
      expect(fiom.crescita_precedente).to be_within(0.01).of(50.0)
      expect(fiom.crescita_anno).to be_within(0.01).of(25.0)
      expect(fiom.differenza).to be_within(0.01).of(-25.0)
      expect(result.gaps.find { |gap| gap.categoria == "FILLEA" }.crescita_precedente).to be_nil
    end

    it "somma l'integrazione FILLEA solo alla riga FILLEA" do
      create(:integration_fillea, zoning:, year: "2026", subscribers_ce: 10)

      expect(result.rows_anno.map(&:counts)).to eq([ [ 12, 12 ], [ 4, 5 ] ])
    end
  end
end
