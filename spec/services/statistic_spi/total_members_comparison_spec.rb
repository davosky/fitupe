require "rails_helper"

RSpec.describe StatisticSpi::TotalMembersComparison do
  let(:zoning) { create(:zoning) }

  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando mancano i dati dell'anno precedente" do
    before do
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")
    end

    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2025/)
    end
  end

  context "quando mancano i dati dell'anno scelto" do
    before do
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")
    end

    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2026/)
    end
  end

  context "quando un pensionato ha piu' deleghe" do
    before do
      # Stesso codice fiscale, due deleghe (reversibilita'): le deleghe contano
      # entrambe, gli iscritti vanno contati una volta sola.
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U")
    end

    it "differenzia il totale deleghe dal totale iscritti" do
      expect(result).to be_success
      expect(result.deleghe_totale.count_precedente).to eq(2)
      expect(result.deleghe_totale.count_anno).to eq(1)
      expect(result.iscritti_totale.count_precedente).to eq(1)
      expect(result.iscritti_totale.count_anno).to eq(1)
    end
  end

  context "quando esistono dati per entrambi gli anni" do
    before do
      create_list(:import_spi, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno")
      create_list(:import_spi, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno")
    end

    it "conta gli iscritti e le deleghe di entrambi gli anni e calcola la differenza" do
      expect(result).to be_success
      expect(result.deleghe_totale.count_precedente).to eq(3)
      expect(result.deleghe_totale.count_anno).to eq(2)
      expect(result.deleghe_totale.diff).to eq(-1)
      expect(result.deleghe_totale.diff_percent).to be_within(0.01).of(-33.33)
    end

    it "non calcola alcun comprensorio quando l'azzonamento non è regionale" do
      expect(result).to be_success
      expect(result.iscritti_comprensori).to be_empty
      expect(result.deleghe_comprensori).to be_empty
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    before do
      # Gorizia 2025: 2 deleghe, stesso pensionato (1 iscritto)
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBB02002")
      # Gorizia 2026: 1 delega, 1 iscritto
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBA01001")
      # Pordenone 2025 e 2026: 1 delega/iscritto ciascuno, soggetti diversi
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_fiscale: "VRDLGU75B02H501Y", codice_azzonamento_completo: "GCC03003")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "BNCPLA60C03H501Z", codice_azzonamento_completo: "GCD04004")
    end

    it "aggiunge una riga per ciascuna provincia, differenziando iscritti e deleghe" do
      expect(result).to be_success
      expect(result.deleghe_comprensori.map { |row| row.zoning.codice_azzonamento }).to eq(%w[GB GC])

      gorizia_deleghe = result.deleghe_comprensori.find { |row| row.zoning == gorizia }
      expect(gorizia_deleghe.count_precedente).to eq(2)
      expect(gorizia_deleghe.count_anno).to eq(1)

      gorizia_iscritti = result.iscritti_comprensori.find { |row| row.zoning == gorizia }
      expect(gorizia_iscritti.count_precedente).to eq(1)
      expect(gorizia_iscritti.count_anno).to eq(1)

      pordenone_deleghe = result.deleghe_comprensori.find { |row| row.zoning == pordenone }
      expect(pordenone_deleghe.count_precedente).to eq(1)
      expect(pordenone_deleghe.count_anno).to eq(1)
    end

    it "il totale regionale iscritti resta coerente con la somma dei comprensori" do
      expect(result.iscritti_totale.count_precedente).to eq(result.iscritti_comprensori.sum(&:count_precedente))
      expect(result.iscritti_totale.count_anno).to eq(result.iscritti_comprensori.sum(&:count_anno))
    end

    it "non calcola alcuna delega multipla quando nessuno ha piu' di una delega nell'anno corrente" do
      expect(result.deleghe_multiple_totale.totale).to eq(0)
      expect(result.deleghe_multiple_comprensori.sum(&:totale)).to eq(0)
    end

    it "il totale regionale tipologie delega resta coerente con la somma dei comprensori" do
      expect(result.tipologie_delega_totale.totale).to eq(result.tipologie_delega_comprensori.sum(&:totale))
      expect(result.tipologie_delega_totale.totale).to eq(2)
    end
  end

  context "quando un pensionato ha piu' deleghe nell'anno corrente in comprensori diversi" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    before do
      create_list(:import_spi, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GBA01001")
      create(:import_spi, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_fiscale: "RSSMRA80A01H501U", codice_azzonamento_completo: "GCB02002")
    end

    it "espone le deleghe multiple riconciliate per comprensorio (assegnate al primo alfabetico)" do
      gorizia_multiple = result.deleghe_multiple_comprensori.find { |row| row.zoning == gorizia }
      pordenone_multiple = result.deleghe_multiple_comprensori.find { |row| row.zoning == pordenone }

      expect(gorizia_multiple.doppia).to eq(1)
      expect(pordenone_multiple.doppia).to eq(0)
      expect(result.deleghe_multiple_totale.doppia).to eq(1)
    end
  end
end
