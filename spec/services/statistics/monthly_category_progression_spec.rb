require "rails_helper"

RSpec.describe Statistics::MonthlyCategoryProgression do
  let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }

  subject(:result) { described_class.call(zoning:, anno: "2026") }

  def iscritti(conteggi, anno)
    conteggi.each do |mese, count|
      create_list(:import, count, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
        mese_di_riferimento: mese, categoria: "FIOM")
    end
  end

  context "quando mancano i dati" do
    it "riporta l'errore della progressione annuale" do
      expect(result).not_to be_success
      expect(result.error).to match(/2026/)
    end
  end

  context "quando esistono dati per entrambi gli anni" do
    before do
      iscritti({ "Gennaio" => 4, "Febbraio" => 6, "Marzo" => 3, "Aprile" => 4 }, "2026")
      iscritti({ "Gennaio" => 2, "Febbraio" => 3, "Marzo" => 5, "Aprile" => 6 }, "2025")
    end

    it "trova il mese di maggior progressione e di maggior regressione dell'anno scelto" do
      fiom = result.rows.sole
      expect(fiom.anno.progressione.to_h).to include(mese: "Febbraio", diff: 2)
      expect(fiom.anno.progressione.diff_percent).to be_within(0.01).of(50.0)
      expect(fiom.anno.regressione.to_h).to include(mese: "Marzo", diff: -3)
    end

    it "lascia vuota la regressione dell'anno precedente se non c'è nessun calo" do
      fiom = result.rows.sole
      expect(fiom.precedente.progressione.to_h).to include(mese: "Marzo", diff: 2)
      expect(fiom.precedente.regressione).to be_nil
    end
  end
end
