require "rails_helper"

RSpec.describe StatisticPrints::ReportPdf do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Gennaio") }

  it "non inserisce la pagina Legenda quando non esiste un record corrispondente" do
    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(7)
  end

  it "inserisce la pagina Legenda subito dopo la copertina quando esiste un record corrispondente" do
    create(:legend, zoning: zoning, year: "2026", month: "Gennaio", description: "<div>Nota informativa</div>")

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(8)
  end

  it "ignora una legenda di un altro mese" do
    create(:legend, zoning: zoning, year: "2026", month: "Febbraio")

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(7)
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

    expect(pdf.page_count).to eq(8)
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
      create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone")
    end

    it "ripete l'intero set di pagine per ciascun comprensorio, con una pagina divisoria per ognuno" do
      pdf = described_class.call(form: form)

      # copertina + 6 pagine regionali + 2 comprensori * (1 divisoria + 6 pagine)
      expect(pdf.page_count).to eq(1 + 6 + (2 * 7))
    end

    it "non ripete nulla per un azzonamento provinciale" do
      provincia_form = TotalMembersForm.new(zoning_id: create(:zoning, codice_azzonamento: "GD").id,
        anno: "2026", mese: "Gennaio")

      pdf = described_class.call(form: provincia_form)

      expect(pdf.page_count).to eq(7)
    end
  end

  context "con un comparison_service diverso da quello di default (Stampa Statistiche Con Integrazioni)" do
    it "genera lo stesso numero di pagine usando StatisticWithIntegrations::TotalMembersComparison" do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Gennaio")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Gennaio")

      pdf = described_class.call(form: form, comparison_service: StatisticWithIntegrations::TotalMembersComparison)

      expect(pdf.page_count).to eq(7)
    end

    it "invoca davvero il comparison_service passato, non quello di default" do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Gennaio")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Gennaio")
      allow(StatisticWithIntegrations::TotalMembersComparison).to receive(:call).and_call_original

      described_class.call(form: form, comparison_service: StatisticWithIntegrations::TotalMembersComparison)

      expect(StatisticWithIntegrations::TotalMembersComparison).to have_received(:call)
        .with(zoning: zoning, anno: "2026", mese: "Gennaio").at_least(:once)
    end
  end
end
