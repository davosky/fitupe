require "rails_helper"

RSpec.describe Statistics::DelegationTypeBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) do
    described_class.call(zoning: zoning, anno: "2026", anno_precedente: "2025", mese: "Giugno")
  end

  it "restituisce una riga per ciascuna tipologia di delega, nell'ordine atteso" do
    expect(rows.map(&:tipologia)).to eq(
      [ "Ordinaria", "Ordinaria C.E.", "NASPI", "DS Agricola", "Delega Tesoro", "Concomitante", "Conc. SPI Anno" ]
    )
  end

  it "conta le deleghe in base al valore esatto di tipologia_delega" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria")
    create_list(:import, 4, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria")

    ordinaria = rows.find { |row| row.tipologia == "Ordinaria" }
    expect(ordinaria.count_precedente).to eq(3)
    expect(ordinaria.count_anno).to eq(4)
    expect(ordinaria.diff).to eq(1)
    expect(ordinaria.diff_percent).to be_within(0.01).of(33.33)
  end

  it "conta la Ordinaria C.E. dal valore 'Ordinaria Cassa Edile'" do
    create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria Cassa Edile")

    ordinaria_ce = rows.find { |row| row.tipologia == "Ordinaria C.E." }
    expect(ordinaria_ce.count_anno).to eq(2)
  end

  it "conta il Conc. SPI Anno dalla colonna concomitante_spi_anno, non da tipologia_delega" do
    create_list(:import, 5, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", concomitante_spi_anno: "SI")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", concomitante_spi_anno: "NO", tipologia_delega: "Concomitante")

    conc_spi_anno = rows.find { |row| row.tipologia == "Conc. SPI Anno" }
    expect(conc_spi_anno.count_anno).to eq(5)

    concomitante = rows.find { |row| row.tipologia == "Concomitante" }
    expect(concomitante.count_anno).to eq(1)
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 3, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_delega: "Ordinaria", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", anno_precedente: "2025", mese: "Giugno")

    ordinaria = righe.find { |row| row.tipologia == "Ordinaria" }
    expect(ordinaria.count_precedente).to eq(3)
    expect(ordinaria.count_anno).to eq(0)
  end
end
