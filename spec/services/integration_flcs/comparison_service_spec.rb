require "rails_helper"

RSpec.describe IntegrationFlcs::ComparisonService do
  let(:zoning) { create(:zoning) }
  let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/anagrafe_flc_sample.csv"), "text/csv") }

  subject(:result) { described_class.call(file: file, zoning_id: zoning.id, year: "2026", month: "Giugno") }

  context "quando non esiste alcuna importazione SinCGIL per lo stesso periodo" do
    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/prima caricare i dati SinCGIL/)
    end
  end

  context "quando l'importazione SinCGIL esiste" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria: "FLC", codice_fiscale: "RSSMRA80A01H501U",
        codice_azzonamento_completo: "#{zoning.codice_azzonamento}0101")
    end

    it "crea l'integrazione con il conteggio dei codici fiscali mancanti in SinCGIL" do
      expect(result).to be_success
      expect(result.integration_flc).to be_persisted
      expect(result.integration_flc.subscribers_af).to eq(2)
      expect(result.integration_flc.zoning).to eq(zoning)
      expect(result.integration_flc.year).to eq("2026")
      expect(result.integration_flc.month).to eq("Giugno")
    end

    it "ignora gli iscritti SinCGIL di categoria diversa da FLC" do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria: "FILCAMS", codice_fiscale: "VRDGPP75M20L219K",
        codice_azzonamento_completo: "#{zoning.codice_azzonamento}0102")

      expect(result.integration_flc.subscribers_af).to eq(2)
    end

    it "ignora gli iscritti SinCGIL di un'altra provincia con lo stesso azzonamento_di_riferimento" do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria: "FLC", codice_fiscale: "VRDGPP75M20L219K", codice_azzonamento_completo: "ALTRO0102")

      expect(result.integration_flc.subscribers_af).to eq(2)
    end

    it "aggiorna il record esistente invece di duplicarlo" do
      existing = create(:integration_flc, zoning: zoning, year: "2026", month: "Giugno", subscribers_af: 0)

      expect { result }.not_to change(IntegrationFlc, :count)
      expect(result.integration_flc).to eq(existing)
      expect(result.integration_flc.reload.subscribers_af).to eq(2)
    end
  end

  context "quando il batch usa la colonna categoria_sindacale invece di categoria" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria_sindacale: "FLC", categoria: nil, codice_fiscale: "RSSMRA80A01H501U",
        codice_azzonamento_completo: "#{zoning.codice_azzonamento}0101")
    end

    it "usa categoria_sindacale quando è quella valorizzata per il periodo" do
      expect(result).to be_success
      expect(result.integration_flc.subscribers_af).to eq(2)
    end
  end

  context "quando l'importazione SinCGIL esiste solo a livello di azzonamento regionale" do
    let(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "Friuli Venezia Giulia") }
    let(:provincia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    subject(:result) { described_class.call(file: file, zoning_id: provincia.id, year: "2026", month: "Giugno") }

    before do
      create(:import, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria: "FLC", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GB0101")
    end

    it "procede usando anche gli iscritti importati sotto l'azzonamento regionale" do
      expect(result).to be_success
      expect(result.integration_flc.subscribers_af).to eq(2)
      expect(result.integration_flc.zoning).to eq(provincia)
    end

    it "esclude dal conteggio le altre province presenti nello stesso import regionale" do
      create(:import, azzonamento_di_riferimento: regione, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria: "FLC", codice_fiscale: "VRDGPP75M20L219K", codice_azzonamento_completo: "GA0101")

      expect(result.integration_flc.subscribers_af).to eq(2)
    end
  end

  context "quando esiste solo un'importazione per un'altra provincia della stessa regione" do
    let!(:regione) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "Friuli Venezia Giulia") }
    let(:trieste) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }
    let(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

    subject(:result) { described_class.call(file: file, zoning_id: gorizia.id, year: "2026", month: "Giugno") }

    before do
      create(:import, azzonamento_di_riferimento: trieste, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria: "FLC", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GA0101")
    end

    it "fallisce perché l'importazione di un'altra provincia non basta" do
      expect(result).not_to be_success
      expect(result.error).to match(/prima caricare i dati SinCGIL/)
    end
  end
end
