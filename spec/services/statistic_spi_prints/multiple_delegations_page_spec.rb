require "rails_helper"

RSpec.describe StatisticSpiPrints::MultipleDelegationsPage do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Giugno") }

  def build_pdf
    pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape)
    asap_dir = Rails.root.join("app/assets/fonts")
    pdf.font_families.update(
      "AsapCondensed" => {
        normal: asap_dir.join("AsapCondensed-Regular.ttf"), bold: asap_dir.join("AsapCondensed-Bold.ttf"),
        italic: asap_dir.join("AsapCondensed-Italic.ttf"), bold_italic: asap_dir.join("AsapCondensed-BoldItalic.ttf")
      }
    )
    pdf
  end

  it "disegna la tabella anche senza dati per il periodo" do
    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  it "disegna le deleghe multiple a livello di singolo comprensorio" do
    create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      codice_fiscale: "RSSMRA80A01H501U")
    create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      codice_fiscale: "RSSMRA80A01H501U")

    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
      create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBB02002")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "VRDLGU75B02H501Y", codice_azzonamento_completo: "GCC03003")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "VRDLGU75B02H501Y", codice_azzonamento_completo: "GCD04004")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_fiscale: "VRDLGU75B02H501Y", codice_azzonamento_completo: "GCC03003")
    end

    it "disegna anche la tabella dei comprensori senza errori" do
      expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
    end
  end
end
