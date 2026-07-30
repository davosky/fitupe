require "rails_helper"

RSpec.describe StatisticPrints::EmploymentStatusPage do
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

  it "disegna la pagina senza errori quando esistono dati" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "SPI")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "FILLEA")

    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  it "disegna un messaggio quando manca l'anno precedente" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "FILLEA")

    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end
end
