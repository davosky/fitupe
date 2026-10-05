require "rails_helper"

RSpec.describe StatisticSpiPrints::ZoningDividerPage do
  it "disegna la pagina senza errori su un'unica pagina" do
    zoning = build(:zoning, descrizione_azzonamento: "Gorizia")
    pdf = build_pdf

    expect { described_class.draw(pdf, zoning: zoning, mese: "Giugno", anno: "2026") }.not_to raise_error
    expect(pdf.page_count).to eq(1)
  end

  it "usa il logo CGIL+SPI e la dicitura dei pensionati" do
    pdf = build_pdf
    expect(pdf).to receive(:image).with(Rails.root.join("app/assets/images/statistic_prints/logo-cgil-spi.png").to_s,
      anything).twice.and_call_original
    expect(pdf).to receive(:text_box).with("Sindacato Pensionati Italiani", anything).and_call_original
    allow(pdf).to receive(:text_box).and_call_original

    described_class.draw(pdf, zoning: build(:zoning), mese: "Giugno", anno: "2026")
  end
end
