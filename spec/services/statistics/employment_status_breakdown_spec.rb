require "rails_helper"

RSpec.describe Statistics::EmploymentStatusBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) do
    described_class.call(zoning: zoning, anno: "2026", anno_precedente: "2025", mese: "Giugno")
  end

  it "somma tutte le categorie tranne SPI negli Attivi e isola SPI nei Pensionati" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "FILLEA")
    create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "FLC")
    create_list(:import, 5, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "SPI")

    create_list(:import, 4, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "FILLEA")
    create_list(:import, 6, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "SPI")

    expect(rows.map(&:gruppo)).to eq(%w[Attivi Pensionati])

    attivi = rows.find { |row| row.gruppo == "Attivi" }
    expect(attivi.count_precedente).to eq(5)
    expect(attivi.count_anno).to eq(4)

    pensionati = rows.find { |row| row.gruppo == "Pensionati" }
    expect(pensionati.count_precedente).to eq(5)
    expect(pensionati.count_anno).to eq(6)
    expect(pensionati.diff).to eq(1)
    expect(pensionati.diff_percent).to be_within(0.01).of(20.0)
  end

  it "conta come Attivi i record senza categoria" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      categoria: nil)

    attivi = rows.find { |row| row.gruppo == "Attivi" }
    expect(attivi.count_anno).to eq(1)
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 3, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "SPI", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", anno_precedente: "2025", mese: "Giugno")

    pensionati = righe.find { |row| row.gruppo == "Pensionati" }
    expect(pensionati.count_precedente).to eq(3)
    expect(pensionati.count_anno).to eq(0)
  end
end
