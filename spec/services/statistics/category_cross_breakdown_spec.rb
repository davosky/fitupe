require "rails_helper"

RSpec.describe Statistics::CategoryCrossBreakdown do
  let(:zoning) { create(:zoning) }
  let(:altro) { true }

  subject(:rows) do
    described_class.call(zoning: zoning, anno: "2026", mese: "Giugno", column: :sesso,
      values: Statistics::GenderBreakdown::SESSI, altro: altro)
  end

  def import(attrs)
    create(:import, { azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno" }.merge(attrs))
  end

  def cell(categoria, label)
    rows.find { |row| row.categoria == categoria }.cells.find { |c| c.label == label }
  end

  context "quando esistono iscritti in più categorie" do
    before do
      3.times { import(categoria_sindacale: "FIOM", sesso: "F") }
      import(categoria_sindacale: "FIOM", sesso: "M")
      import(categoria: "FILCAMS", sesso: "M")
      import(categoria: "FILCAMS", sesso: nil)
    end

    it "restituisce una riga per categoria in ordine alfabetico, unendo categoria e categoria_sindacale" do
      expect(rows.map(&:categoria)).to eq(%w[FILCAMS FIOM])
      expect(rows.first.cells.map(&:label)).to eq(%w[FEMMINE MASCHI ALTRO])
    end

    it "calcola conteggio e percentuale sul totale della singola categoria" do
      expect(cell("FIOM", "FEMMINE").count).to eq(3)
      expect(cell("FIOM", "FEMMINE").percentuale).to be_within(0.01).of(75.0)
      expect(cell("FIOM", "MASCHI").percentuale).to be_within(0.01).of(25.0)
    end

    it "mette in ALTRO gli iscritti senza un valore elencato" do
      expect(cell("FILCAMS", "ALTRO").count).to eq(1)
      expect(cell("FILCAMS", "ALTRO").percentuale).to be_within(0.01).of(50.0)
      expect(cell("FIOM", "ALTRO").count).to eq(0)
    end

    context "senza la colonna ALTRO" do
      let(:altro) { false }

      it "espone solo i valori elencati e calcola la percentuale sulla loro somma" do
        expect(rows.first.cells.map(&:label)).to eq(%w[FEMMINE MASCHI])
        expect(cell("FILCAMS", "MASCHI").percentuale).to be_within(0.01).of(100.0)
      end
    end
  end

  context "quando ci sono record di altri anni o senza categoria" do
    before do
      import(categoria: "FIOM", sesso: "F", anno_di_riferimento: "2025")
      import(categoria: nil, sesso: "F")
    end

    it "li ignora" do
      expect(rows).to be_empty
    end
  end

  context "quando l'azzonamento non ha importazioni dirette" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let(:regionale) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      import(azzonamento_di_riferimento: regionale, categoria: "FIOM", sesso: "F", codice_azzonamento_completo: "GB001")
      import(azzonamento_di_riferimento: regionale, categoria: "FIOM", sesso: "F", codice_azzonamento_completo: "GA001")
    end

    it "ricade sull'azzonamento superiore filtrato per codice_azzonamento_completo" do
      expect(cell("FIOM", "FEMMINE").count).to eq(1)
    end
  end
end
