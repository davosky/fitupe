require "rails_helper"

RSpec.describe StatisticSpiPrints::TipologieDelegaPage do
  let(:zoning) { create(:zoning) }
  let(:form) { TotalMembersForm.new(zoning_id: zoning.id, anno: "2026", mese: "Giugno") }

  it "disegna la tabella e il grafico anche senza dati per il periodo" do
    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  it "disegna le tipologie delega a livello di singolo comprensorio" do
    create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      tipologia_delega: "Ordinaria")
    create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
      tipologia_delega: "Concomitante")

    expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
      create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_azzonamento_completo: "GBA01001", tipologia_delega: "Ordinaria")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_azzonamento_completo: "GBB02002", tipologia_delega: "Concomitante")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_azzonamento_completo: "GCC03003", tipologia_delega: "Invalidi civili")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        codice_azzonamento_completo: "GCD04004", tipologia_delega: "Pagamento Diretto (Brevi Manu)")
    end

    it "disegna anche le tabelle dei comprensori senza errori" do
      expect { described_class.draw(build_pdf, form: form) }.not_to raise_error
    end
  end
end
