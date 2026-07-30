require "rails_helper"

RSpec.describe StatisticPrints::MembershipTypesPage do
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

  it "disegna entrambe le tabelle e il grafico su un'unica pagina quando esistono dati" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega", tipologia_delega: "Ordinaria")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "BreviManu", tipologia_delega: "NASPI")

    pdf = build_pdf
    expect { described_class.draw(pdf, form: form) }.not_to raise_error
    expect(pdf.page_count).to eq(1)
  end

  it "disegna un messaggio quando manca l'anno precedente" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega")

    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  it "usa il comparison_service passato invece di quello di default" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega", tipologia_delega: "Ordinaria")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", tipologia_iscrizione: "BreviManu", tipologia_delega: "NASPI")

    expect {
      described_class.draw(build_pdf, form: form, comparison_service: StatisticWithIntegrations::TotalMembersComparison)
    }.not_to raise_error
  end
end
