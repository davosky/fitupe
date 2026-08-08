require "rails_helper"

RSpec.describe StatisticSpiPrints::ReportPdf do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Gennaio") }

  it "non inserisce la pagina Legenda SPI quando non esiste un record corrispondente" do
    pdf = described_class.call(form: form)

    # copertina + [divisoria + totali + deleghe multiple + tipologie delega + cessazioni + provvisorie
    # + classi di età] (interno pari: 8, nessuna bianca) + controcopertina
    expect(pdf.page_count).to eq(9)
  end

  it "inserisce la pagina Legenda SPI subito dopo la copertina quando esiste un record corrispondente" do
    create(:legend_spi, zoning: zoning, year: "2026", month: "Gennaio", description: "<div>Nota informativa</div>")

    pdf = described_class.call(form: form)

    # copertina + legenda + [divisoria + totali + deleghe multiple + tipologie delega + cessazioni
    # + provvisorie + classi di età] (interno dispari: 9) + bianca + controcopertina
    expect(pdf.page_count).to eq(11)
  end

  it "ignora una legenda SPI di un altro mese" do
    create(:legend_spi, zoning: zoning, year: "2026", month: "Febbraio")

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(9)
  end

  it "genera il PDF anche con una legenda SPI che contiene grassetto, elenchi e una linea orizzontale" do
    description = <<~HTML
      <div>Testo con <u>sottolineato</u> e <strong>grassetto</strong>.</div>
      <p>Paragrafo giustificato.</p>
      <ul><li>Punto uno</li></ul>
      <action-text-attachment content-type="text/html" content="&lt;hr&gt;"></action-text-attachment>
    HTML
    create(:legend_spi, zoning: zoning, year: "2026", month: "Gennaio", description: description)

    pdf = described_class.call(form: form)

    expect(pdf.page_count).to eq(11)
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste")
      create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    end

    it "ripete la pagina divisoria e il set di pagine di contenuto per ciascun comprensorio" do
      pdf = described_class.call(form: form)

      # copertina + 3 sezioni (regionale + Trieste + Gorizia) da 7 pagine ciascuna (divisoria + 6 di
      # contenuto) = 22 (interno pari, nessuna bianca) + controcopertina
      expect(pdf.page_count).to eq(23)
    end
  end
end
