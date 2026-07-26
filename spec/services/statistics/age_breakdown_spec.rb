require "rails_helper"

RSpec.describe Statistics::AgeBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  it "restituisce una riga per ciascuna fascia d'età, nell'ordine crescente previsto" do
    expect(rows.map(&:fascia)).to eq(%w[GIOVANI TRENTENNI QUARANTENNI CINQUANTENNI SESSANTENNI SETTANTENNI
      OTTANTENNI NOVANTENNI HIGHLANDERS])
  end

  it "assegna correttamente gli iscritti alle fasce, inclusi i confini esatti" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 25.years.ago.to_date)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 30.years.ago.to_date)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 105.years.ago.to_date)

    expect(rows.find { |row| row.fascia == "GIOVANI" }.count).to eq(1)
    expect(rows.find { |row| row.fascia == "TRENTENNI" }.count).to eq(1)
    expect(rows.find { |row| row.fascia == "HIGHLANDERS" }.count).to eq(1)
  end

  it "ignora i record senza data di nascita" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: nil)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 45.years.ago.to_date)

    expect(rows.find { |row| row.fascia == "QUARANTENNI" }.count).to eq(1)
    expect(rows.sum(&:count)).to eq(1)
  end

  it "calcola la percentuale sul totale iscritti del periodo, non solo sui record con data di nascita" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 45.years.ago.to_date)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: nil)

    quarantenni = rows.find { |row| row.fascia == "QUARANTENNI" }
    expect(quarantenni.count).to eq(3)
    expect(quarantenni.percentuale).to be_within(0.01).of(75.0)
  end

  it "non compara con l'anno precedente e ignora record di altri anni" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", data_nascita: 45.years.ago.to_date)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 45.years.ago.to_date)

    expect(rows.find { |row| row.fascia == "QUARANTENNI" }.count).to eq(1)
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 2, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", data_nascita: 45.years.ago.to_date, codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", mese: "Giugno")

    expect(righe.find { |row| row.fascia == "QUARANTENNI" }.count).to eq(2)
  end
end
