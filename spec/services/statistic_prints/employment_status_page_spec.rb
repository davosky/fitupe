require "rails_helper"

RSpec.describe StatisticPrints::EmploymentStatusPage do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Giugno") }

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

  it "usa il comparison_service passato invece di quello di default" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", categoria: "SPI")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", categoria: "FILLEA")

    expect {
      described_class.draw(build_pdf, form: form, comparison_service: StatisticWithIntegrations::TotalMembersComparison)
    }.not_to raise_error
  end
end
