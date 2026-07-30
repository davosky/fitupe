require "rails_helper"

RSpec.describe StatisticPrints::ZoningDividerPage do
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

  it "disegna la pagina senza errori su un'unica pagina" do
    zoning = build(:zoning, descrizione_azzonamento: "Gorizia")
    pdf = build_pdf

    expect { described_class.draw(pdf, zoning: zoning, mese: "Giugno", anno: "2026") }.not_to raise_error
    expect(pdf.page_count).to eq(1)
  end
end
