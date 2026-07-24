require "rails_helper"

RSpec.describe Statistics::NationalityBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  it "restituisce una riga per ciascuna nazionalità, nell'ordine atteso" do
    expect(rows.map(&:nazionalita)).to eq(%w[ITALIANA UE EXTRAUE])
  end

  it "conta gli iscritti in base al valore esatto di nazionalita e calcola la percentuale sul totale" do
    create_list(:import, 6, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", nazionalita: "ITALIA")
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", nazionalita: "UE")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", nazionalita: "EXTRAUE")

    italiana = rows.find { |row| row.nazionalita == "ITALIANA" }
    expect(italiana.count).to eq(6)
    expect(italiana.percentuale).to be_within(0.01).of(60.0)

    ue = rows.find { |row| row.nazionalita == "UE" }
    expect(ue.count).to eq(3)
    expect(ue.percentuale).to be_within(0.01).of(30.0)

    extraue = rows.find { |row| row.nazionalita == "EXTRAUE" }
    expect(extraue.count).to eq(1)
    expect(extraue.percentuale).to be_within(0.01).of(10.0)
  end

  it "non compara con l'anno precedente e ignora record di altri anni" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", nazionalita: "ITALIA")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", nazionalita: "ITALIA")

    italiana = rows.find { |row| row.nazionalita == "ITALIANA" }
    expect(italiana.count).to eq(1)
  end

  it "restituisce percentuale nil quando non ci sono iscritti" do
    italiana = rows.find { |row| row.nazionalita == "ITALIANA" }
    expect(italiana.count).to eq(0)
    expect(italiana.percentuale).to be_nil
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 2, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", nazionalita: "ITALIA", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", mese: "Giugno")

    italiana = righe.find { |row| row.nazionalita == "ITALIANA" }
    expect(italiana.count).to eq(2)
  end
end
