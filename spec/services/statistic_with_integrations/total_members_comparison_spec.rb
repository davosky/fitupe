require "rails_helper"

RSpec.describe StatisticWithIntegrations::TotalMembersComparison do
  let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }

  subject(:result) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  context "quando mancano i dati SinCGIL (Statistics fallisce)" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")
    end

    it "propaga l'errore di Statistics::TotalMembersComparison" do
      expect(result).not_to be_success
      expect(result.error).to match(/2025/)
    end
  end

  context "quando i dati SinCGIL esistono ma manca il dato Cassa Edile per l'anno corrente" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")
    end

    it "si blocca con un messaggio esplicativo" do
      expect(result).not_to be_success
      expect(result.error).to match(/Gorizia/)
    end
  end

  context "quando esiste il dato Cassa Edile ma manca l'Anagrafe FLC del mese precedente" do
    before do
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")
      create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 400)
    end

    it "si blocca con un messaggio esplicativo sull'Anagrafe FLC" do
      expect(result).not_to be_success
      expect(result.error).to match(/Anagrafe FLC/)
      expect(result.error).to match(/Gorizia/)
    end
  end

  context "quando esistono i dati SinCGIL, Cassa Edile e Anagrafe FLC" do
    before do
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FLC")

      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FLC")
    end

    context "quando esistono i dati per l'anno precedente di entrambe le integrazioni" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 400)
        create(:integration_fillea, zoning: zoning, year: "2025", subscribers_ce: 300)
        # l'Anagrafe FLC di Giugno si legge dal record di Maggio (mese precedente)
        create(:integration_flc, zoning: zoning, year: "2026", month: "Maggio", subscribers_af: 50)
        create(:integration_flc, zoning: zoning, year: "2025", month: "Maggio", subscribers_af: 30)
      end

      it "ricalibra il totale sommando entrambe le correzioni di entrambi gli anni" do
        expect(result).to be_success
        # 5 SinCGIL + (400 - 3) Cassa Edile + 50 Anagrafe FLC (somma pura)
        expect(result.count_anno).to eq(452)
        # 3 SinCGIL + (300 - 2) Cassa Edile + 30 Anagrafe FLC (somma pura)
        expect(result.count_precedente).to eq(331)
        expect(result.diff).to eq(121)
        expect(result.diff_percent).to be_within(0.01).of(36.56)
      end

      it "ricalibra la riga FILLEA di categorie con la sola correzione Cassa Edile" do
        fillea = result.categorie.find { |row| row.categoria == "FILLEA" }
        expect(fillea.count_anno).to eq(400)
        expect(fillea.count_precedente).to eq(300)
      end

      it "ricalibra la riga FLC di categorie sommando l'Anagrafe FLC" do
        flc = result.categorie.find { |row| row.categoria == "FLC" }
        expect(flc.count_anno).to eq(52) # 2 SinCGIL + 50 Anagrafe FLC
        expect(flc.count_precedente).to eq(31) # 1 SinCGIL + 30 Anagrafe FLC
      end

      it "ricalibra la riga Ordinaria C.E. di tipologie_delega" do
        ordinaria_ce = result.tipologie_delega.find { |row| row.tipologia == "Ordinaria C.E." }
        expect(ordinaria_ce.count_anno).to eq(400)
        expect(ordinaria_ce.count_precedente).to eq(300)
      end

      it "riporta la stessa somma Anagrafe FLC sulla riga Delega Tesoro di tipologie_delega" do
        delega_tesoro = result.tipologie_delega.find { |row| row.tipologia == "Delega Tesoro" }
        expect(delega_tesoro.count_anno).to eq(50) # 0 SinCGIL + 50 Anagrafe FLC
        expect(delega_tesoro.count_precedente).to eq(30) # 0 SinCGIL + 30 Anagrafe FLC
      end

      it "non tocca le altre righe di tipologie_delega" do
        ordinaria = result.tipologie_delega.find { |row| row.tipologia == "Ordinaria" }
        expect(ordinaria.count_anno).to eq(0)
        expect(ordinaria.count_precedente).to eq(0)
      end

      it "espone il dettaglio di entrambe le correzioni" do
        expect(result.fillea_correzione.total_diff).to eq(397)
        expect(result.flc_correzione.total_diff).to eq(50)
      end

      it "non altera le sezioni senza equivalente esterno" do
        expect(result.nazionalita.map(&:count)).to eq(
          Statistics::NationalityBreakdown.call(zoning: zoning, anno: "2026", mese: "Giugno").map(&:count)
        )
      end
    end

    context "quando manca il dato Cassa Edile per l'anno precedente ma l'Anagrafe FLC è completa" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 400)
        create(:integration_flc, zoning: zoning, year: "2026", month: "Maggio", subscribers_af: 50)
        create(:integration_flc, zoning: zoning, year: "2025", month: "Maggio", subscribers_af: 30)
      end

      it "non si blocca e applica solo la correzione Anagrafe FLC all'anno precedente" do
        expect(result).to be_success
        # 3 SinCGIL + 0 (Cassa Edile non disponibile) + 30 Anagrafe FLC
        expect(result.count_precedente).to eq(33)
        expect(result.count_anno).to eq(452)
      end
    end

    context "quando manca il dato Anagrafe FLC per l'anno precedente ma la Cassa Edile è completa" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 400)
        create(:integration_fillea, zoning: zoning, year: "2025", subscribers_ce: 300)
        create(:integration_flc, zoning: zoning, year: "2026", month: "Maggio", subscribers_af: 50)
      end

      it "non si blocca e applica solo la correzione Cassa Edile all'anno precedente" do
        expect(result).to be_success
        # 3 SinCGIL + (300 - 2) Cassa Edile + 0 (Anagrafe FLC non disponibile)
        expect(result.count_precedente).to eq(301)
        expect(result.count_anno).to eq(452)
      end
    end
  end

  context "quando l'azzonamento scelto è regionale e una provincia non ha alcun dato di integrazione" do
    let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG") }
    let!(:gorizia) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia") }
    let!(:pordenone) { create(:zoning, codice_azzonamento: "GC", descrizione_azzonamento: "Pordenone") }

    before do
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile",
        codice_azzonamento_completo: "GB001")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile",
        codice_azzonamento_completo: "GC001")

      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile",
        codice_azzonamento_completo: "GB002")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile",
        codice_azzonamento_completo: "GC002")

      create(:integration_fillea, zoning: gorizia, year: "2026", subscribers_ce: 400)
      create(:integration_fillea, zoning: gorizia, year: "2025", subscribers_ce: 300)
      # Pordenone non ha né Cassa Edile né Anagrafe FLC
    end

    it "non si blocca, integra Gorizia e lascia Pordenone invariato nei comprensori" do
      expect(result).to be_success

      gorizia_row = result.comprensori.find { |row| row.zoning == gorizia }
      expect(gorizia_row.count_anno).to eq(400) # 3 SinCGIL + 397 Cassa Edile
      expect(gorizia_row.count_precedente).to eq(300) # 2 SinCGIL + 298 Cassa Edile

      pordenone_row = result.comprensori.find { |row| row.zoning == pordenone }
      expect(pordenone_row.count_anno).to eq(2) # invariato, nessun dato di integrazione
      expect(pordenone_row.count_precedente).to eq(1) # invariato
    end

    it "il totale regionale riflette solo la correzione della provincia con dati disponibili" do
      expect(result.count_anno).to eq(402) # 5 SinCGIL + 397 Cassa Edile (solo Gorizia)
      expect(result.count_precedente).to eq(301) # 3 SinCGIL + 298 Cassa Edile
    end
  end
end
