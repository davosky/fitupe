require "rails_helper"

RSpec.describe Statistics::TotalMembersComparison do
  let(:zoning) { create(:zoning) }

  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando mancano i dati dell'anno precedente" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")
    end

    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2025/)
    end
  end

  context "quando mancano i dati dell'anno scelto" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")
    end

    it "fallisce con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/2026/)
    end
  end

  context "quando esistono dati per entrambi gli anni" do
    before do
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno")
    end

    it "conta gli iscritti di entrambi gli anni e calcola la differenza" do
      expect(result).to be_success
      expect(result.count_precedente).to eq(3)
      expect(result.count_anno).to eq(2)
      expect(result.diff).to eq(-1)
      expect(result.diff_percent).to be_within(0.01).of(-33.33)
    end

    it "non conta gli iscritti di un altro azzonamento" do
      altro = create(:zoning, codice_azzonamento: "H")
      create_list(:import, 5, azzonamento_di_riferimento: altro, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno")

      expect(result.count_anno).to eq(2)
    end

    it "non conta gli iscritti di un altro mese" do
      create_list(:import, 5, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Luglio")

      expect(result.count_anno).to eq(2)
    end
  end

  context "quando l'azzonamento scelto non ha importazioni ma esiste quello superiore" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Pordenone") }
    let!(:regional_zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }

    before do
      create_list(:import, 3, azzonamento_di_riferimento: regional_zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GB001")
      create(:import, azzonamento_di_riferimento: regional_zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GC001")
      create_list(:import, 2, azzonamento_di_riferimento: regional_zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GB002")
    end

    it "recupera i dati dall'azzonamento superiore filtrando per codice_azzonamento_completo" do
      expect(result).to be_success
      expect(result.count_precedente).to eq(3)
      expect(result.count_anno).to eq(2)
    end
  end

  context "quando esiste sia l'importazione specifica che quella superiore" do
    let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Pordenone") }

    before do
      create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno")
    end

    it "preferisce l'importazione specifica" do
      expect(result).to be_success
      expect(result.count_precedente).to eq(3)
      expect(result.count_anno).to eq(2)
    end
  end

  context "quando l'azzonamento scelto è regionale" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    before do
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GB001")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GB002")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GC001")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", codice_azzonamento_completo: "GC002")
    end

    it "aggiunge una riga per ciascuna provincia" do
      expect(result).to be_success
      expect(result.comprensori.map { |row| row.zoning.codice_azzonamento }).to eq(%w[GB GC])

      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }
      expect(gorizia_row.count_precedente).to eq(3)
      expect(gorizia_row.count_anno).to eq(2)

      pordenone_row = result.comprensori.find { |row| row.zoning == pordenone }
      expect(pordenone_row.count_precedente).to eq(1)
      expect(pordenone_row.count_anno).to eq(1)
    end
  end

  context "quando l'azzonamento scelto non è regionale" do
    before do
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno")
    end

    it "non calcola alcun comprensorio" do
      expect(result).to be_success
      expect(result.comprensori).to be_empty
    end
  end

  context "quando esistono categorie diverse" do
    before do
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FILLEA")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FILLEA")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FLC")
    end

    it "aggiunge una riga per ciascuna categoria, in ordine alfabetico" do
      expect(result).to be_success
      expect(result.categorie.map(&:categoria)).to eq(%w[FILLEA FLC])

      fillea_row = result.categorie.find { |row| row.categoria == "FILLEA" }
      expect(fillea_row.count_precedente).to eq(3)
      expect(fillea_row.count_anno).to eq(2)

      flc_row = result.categorie.find { |row| row.categoria == "FLC" }
      expect(flc_row.count_precedente).to eq(1)
      expect(flc_row.count_anno).to eq(0)
      expect(flc_row.diff_percent).to eq(-100.0)
    end
  end

  context "quando esistono categorie attive e la categoria SPI" do
    before do
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FILLEA")
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "SPI")
      create_list(:import, 4, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FILLEA")
      create_list(:import, 5, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "SPI")
    end

    it "espone le righe Attivi e Pensionati" do
      expect(result).to be_success
      expect(result.attivi_pensionati.map(&:gruppo)).to eq(%w[Attivi Pensionati])

      attivi = result.attivi_pensionati.find { |row| row.gruppo == "Attivi" }
      expect(attivi.count_precedente).to eq(2)
      expect(attivi.count_anno).to eq(4)

      pensionati = result.attivi_pensionati.find { |row| row.gruppo == "Pensionati" }
      expect(pensionati.count_precedente).to eq(3)
      expect(pensionati.count_anno).to eq(5)
    end
  end

  context "quando esistono iscritti Delega e BreviManu" do
    before do
      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", tipologia_iscrizione: "BreviManu")
      create_list(:import, 4, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_iscrizione: "Delega")
      create_list(:import, 1, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", tipologia_iscrizione: "BreviManu")
    end

    it "espone le righe Delega e BreviManu" do
      expect(result).to be_success
      expect(result.tipologie_iscrizione.map(&:tipologia)).to eq(%w[Delega BreviManu])

      delega = result.tipologie_iscrizione.find { |row| row.tipologia == "Delega" }
      expect(delega.count_precedente).to eq(3)
      expect(delega.count_anno).to eq(4)

      brevi_manu = result.tipologie_iscrizione.find { |row| row.tipologia == "BreviManu" }
      expect(brevi_manu.count_precedente).to eq(2)
      expect(brevi_manu.count_anno).to eq(1)
    end
  end
end
