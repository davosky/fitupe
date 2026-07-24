require "rails_helper"

RSpec.describe Statistics::WorkStatusBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  it "restituisce una riga per ciascuno status lavorativo presente, in ordine alfabetico" do
    create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: "Pensionato")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: "Dipendente")

    expect(rows.map(&:tipologia_status)).to eq(%w[Dipendente Pensionato])
  end

  it "ignora i record senza status lavorativo" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: nil)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: "Dipendente")

    expect(rows.map(&:tipologia_status)).to eq(%w[Dipendente])
  end

  it "calcola la percentuale sul totale iscritti del periodo, non solo sui record con status valorizzato" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: "Dipendente")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: nil)

    dipendente = rows.find { |row| row.tipologia_status == "Dipendente" }
    expect(dipendente.count).to eq(3)
    expect(dipendente.percentuale).to be_within(0.01).of(75.0)
  end

  it "non compara con l'anno precedente e ignora record di altri anni" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_status: "Dipendente")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: "Dipendente")

    dipendente = rows.find { |row| row.tipologia_status == "Dipendente" }
    expect(dipendente.count).to eq(1)
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 2, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_status: "Dipendente", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", mese: "Giugno")

    dipendente = righe.find { |row| row.tipologia_status == "Dipendente" }
    expect(dipendente.count).to eq(2)
  end
end
