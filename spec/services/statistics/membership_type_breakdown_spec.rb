require "rails_helper"

RSpec.describe Statistics::MembershipTypeBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) do
    described_class.call(zoning: zoning, anno: "2026", anno_precedente: "2025", mese: "Giugno")
  end

  it "conta la Delega dal campo tipologia_iscrizione e il resto come BreviManu" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega")
    create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "BreviManu")

    create_list(:import, 4, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega")
    create_list(:import, 1, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "BreviManu")

    expect(rows.map(&:tipologia)).to eq(%w[Delega BreviManu])

    delega = rows.find { |row| row.tipologia == "Delega" }
    expect(delega.count_precedente).to eq(3)
    expect(delega.count_anno).to eq(4)

    brevi_manu = rows.find { |row| row.tipologia == "BreviManu" }
    expect(brevi_manu.count_precedente).to eq(2)
    expect(brevi_manu.count_anno).to eq(1)
    expect(brevi_manu.diff).to eq(-1)
    expect(brevi_manu.diff_percent).to be_within(0.01).of(-50.0)
  end

  it "conta come BreviManu qualunque valore diverso da Delega, incluso nil" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      tipologia_iscrizione: nil)
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      tipologia_iscrizione: "Altro")

    brevi_manu = rows.find { |row| row.tipologia == "BreviManu" }
    expect(brevi_manu.count_anno).to eq(2)
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 3, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", anno_precedente: "2025", mese: "Giugno")

    delega = righe.find { |row| row.tipologia == "Delega" }
    expect(delega.count_precedente).to eq(3)
    expect(delega.count_anno).to eq(0)
  end
end
