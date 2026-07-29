require "rails_helper"

RSpec.describe StatisticPrints::ReportPdf do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Gennaio") }

  it "non inserisce la pagina Legenda quando non esiste un record corrispondente" do
    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(3)
  end

  it "inserisce la pagina Legenda subito dopo la copertina quando esiste un record corrispondente" do
    create(:legend, zoning: zoning, year: "2026", month: "Gennaio", description: "<div>Nota informativa</div>")

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(4)
  end

  it "ignora una legenda di un altro mese" do
    create(:legend, zoning: zoning, year: "2026", month: "Febbraio")

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(3)
  end

  it "genera il PDF anche con una legenda che contiene grassetto, elenchi e una linea orizzontale" do
    description = <<~HTML
      <div>Testo con <u>sottolineato</u> e <strong>grassetto</strong>.</div>
      <p>Paragrafo giustificato.</p>
      <ul><li>Punto uno</li></ul>
      <action-text-attachment content-type="text/html" content="&lt;hr&gt;"></action-text-attachment>
    HTML
    create(:legend, zoning: zoning, year: "2026", month: "Gennaio", description: description)

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(4)
  end
end
