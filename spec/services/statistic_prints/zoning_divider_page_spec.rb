require "rails_helper"

RSpec.describe StatisticPrints::ZoningDividerPage do
  it "disegna la pagina senza errori su un'unica pagina" do
    zoning = build(:zoning, descrizione_azzonamento: "Gorizia")
    pdf = build_pdf

    expect { described_class.draw(pdf, zoning: zoning, mese: "Giugno", anno: "2026") }.not_to raise_error
    expect(pdf.page_count).to eq(1)
  end
end
