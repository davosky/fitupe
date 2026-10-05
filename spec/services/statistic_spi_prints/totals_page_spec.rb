require "rails_helper"

RSpec.describe StatisticSpiPrints::TotalsPage do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Giugno") }

  it "disegna un messaggio quando mancano i dati" do
    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  it "disegna iscritti e deleghe a livello di singolo comprensorio" do
    create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")
    create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")

    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
      create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GBA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GBA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GCC03003")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GCC03003")
    end

    it "disegna anche le tabelle e il grafico dei comprensori senza errori" do
      expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
    end
  end
end
