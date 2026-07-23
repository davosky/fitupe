require "rails_helper"

RSpec.describe Statistics::ZoningPeriodScope do
  subject(:scope) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  let(:zoning) { create(:zoning) }

  it "restituisce le importazioni dell'azzonamento scelto quando esistono" do
    import = create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")

    expect(scope).to contain_exactly(import)
  end

  context "quando l'azzonamento scelto non ha importazioni dirette" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    it "ricade sull'azzonamento superiore filtrando per codice_azzonamento_completo" do
      regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
      match = create(:import, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GB001")
      create(:import, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GC001")

      expect(scope).to contain_exactly(match)
    end

    it "restituisce uno scope vuoto se non esiste nemmeno l'azzonamento superiore" do
      expect(scope).to be_empty
    end
  end
end
