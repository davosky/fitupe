require "rails_helper"

RSpec.describe Statistics::CategoryBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:categorie) do
    described_class.call(zoning: zoning, anno: "2026", anno_precedente: "2025", mese: "Giugno")
  end

  it "restituisce una riga per ciascuna categoria, in ordine alfabetico" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "SPI")
    create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "SPI")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "FILLEA")

    expect(categorie.map(&:categoria)).to eq(%w[FILLEA SPI])

    spi_row = categorie.find { |row| row.categoria == "SPI" }
    expect(spi_row.count_precedente).to eq(3)
    expect(spi_row.count_anno).to eq(2)
    expect(spi_row.diff).to eq(-1)
    expect(spi_row.diff_percent).to be_within(0.01).of(-33.33)
  end

  it "ignora i record senza categoria" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: nil)

    expect(categorie).to be_empty
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 4, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "FLC", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", anno_precedente: "2025", mese: "Giugno")

    flc_row = righe.find { |row| row.categoria == "FLC" }
    expect(flc_row.count_precedente).to eq(4)
    expect(flc_row.count_anno).to eq(0)
  end
end
