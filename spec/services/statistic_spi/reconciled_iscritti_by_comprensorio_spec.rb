require "rails_helper"

RSpec.describe StatisticSpi::ReconciledIscrittiByComprensorio do
  let(:zoning) { create(:zoning, codice_azzonamento: "G") }

  subject(:counts) { described_class.call(ImportSpi.all) }

  it "conta i codici fiscali distinti per comprensorio, un pensionato con piu' deleghe in un solo comprensorio" do
    # Stesso soggetto (RSSMRA80A01H501U), reversibilita' con delega sia a GA che a GB:
    # deve essere contato una sola volta, nel comprensorio alfabeticamente primo.
    create(:import_spi, azzonamento_di_riferimento: zoning, codice_fiscale: "RSSMRA80A01H501U",
      codice_azzonamento_completo: "GBA01001")
    create(:import_spi, azzonamento_di_riferimento: zoning, codice_fiscale: "RSSMRA80A01H501U",
      codice_azzonamento_completo: "GAA01001")
    create(:import_spi, azzonamento_di_riferimento: zoning, codice_fiscale: "VRDLGU75B02H501Y",
      codice_azzonamento_completo: "GBB02002")

    expect(counts).to eq("GA" => 1, "GB" => 1)
  end

  it "resta additivo rispetto al conteggio regionale distinto" do
    create(:import_spi, azzonamento_di_riferimento: zoning, codice_fiscale: "RSSMRA80A01H501U",
      codice_azzonamento_completo: "GBA01001")
    create(:import_spi, azzonamento_di_riferimento: zoning, codice_fiscale: "RSSMRA80A01H501U",
      codice_azzonamento_completo: "GAA01001")
    create(:import_spi, azzonamento_di_riferimento: zoning, codice_fiscale: "VRDLGU75B02H501Y",
      codice_azzonamento_completo: "GBB02002")

    regionale = ImportSpi.distinct.count(:codice_fiscale)

    expect(counts.values.sum).to eq(regionale)
  end
end
