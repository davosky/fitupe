require "rails_helper"

RSpec.describe Statistics::GenderBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  it "restituisce una riga per ciascun sesso, nell'ordine atteso" do
    expect(rows.map(&:sesso)).to eq(%w[FEMMINE MASCHI])
  end

  it "conta gli iscritti in base al valore esatto di sesso e calcola la percentuale sul totale" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", sesso: "F")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", sesso: "M")

    femmine = rows.find { |row| row.sesso == "FEMMINE" }
    expect(femmine.count).to eq(3)
    expect(femmine.percentuale).to be_within(0.01).of(75.0)

    maschi = rows.find { |row| row.sesso == "MASCHI" }
    expect(maschi.count).to eq(1)
    expect(maschi.percentuale).to be_within(0.01).of(25.0)
  end

  it "non compara con l'anno precedente e ignora record di altri anni" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", sesso: "F")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", sesso: "F")

    femmine = rows.find { |row| row.sesso == "FEMMINE" }
    expect(femmine.count).to eq(1)
  end

  it "restituisce percentuale nil quando non ci sono iscritti" do
    femmine = rows.find { |row| row.sesso == "FEMMINE" }
    expect(femmine.count).to eq(0)
    expect(femmine.percentuale).to be_nil
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 2, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", sesso: "F", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", mese: "Giugno")

    femmine = righe.find { |row| row.sesso == "FEMMINE" }
    expect(femmine.count).to eq(2)
  end
end
