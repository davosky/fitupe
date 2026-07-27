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

  context "quando esistono sia i dati SinCGIL che quelli Cassa Edile" do
    before do
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile")
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
        mese_di_riferimento: "Giugno", categoria: "FLC", tipologia_delega: "Ordinaria")

      create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FILLEA", tipologia_delega: "Ordinaria Cassa Edile")
      create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
        mese_di_riferimento: "Giugno", categoria: "FLC", tipologia_delega: "Ordinaria")
    end

    context "quando esiste il dato Cassa Edile anche per l'anno precedente" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 400)
        create(:integration_fillea, zoning: zoning, year: "2025", subscribers_ce: 300)
      end

      it "ricalibra il totale sommando la correzione FILLEA di entrambi gli anni" do
        expect(result).to be_success
        expect(result.count_anno).to eq(402) # 5 SinCGIL + (400 - 3) Cassa Edile
        expect(result.count_precedente).to eq(301) # 3 SinCGIL + (300 - 2) Cassa Edile
        expect(result.diff).to eq(101)
        expect(result.diff_percent).to be_within(0.01).of(33.55)
      end

      it "ricalibra la riga FILLEA di categorie allo stesso modo del totale" do
        fillea = result.categorie.find { |row| row.categoria == "FILLEA" }
        expect(fillea.count_anno).to eq(400)
        expect(fillea.count_precedente).to eq(300)
      end

      it "non tocca le altre righe di categorie" do
        flc = result.categorie.find { |row| row.categoria == "FLC" }
        expect(flc.count_anno).to eq(2)
        expect(flc.count_precedente).to eq(1)
      end

      it "ricalibra la riga Ordinaria C.E. di tipologie_delega" do
        ordinaria_ce = result.tipologie_delega.find { |row| row.tipologia == "Ordinaria C.E." }
        expect(ordinaria_ce.count_anno).to eq(400)
        expect(ordinaria_ce.count_precedente).to eq(300)
      end

      it "non tocca le altre righe di tipologie_delega" do
        ordinaria = result.tipologie_delega.find { |row| row.tipologia == "Ordinaria" }
        expect(ordinaria.count_anno).to eq(2)
        expect(ordinaria.count_precedente).to eq(1)
      end

      it "espone il dettaglio della correzione FILLEA" do
        expect(result.fillea_correzione.total_diff).to eq(397)
        expect(result.fillea_correzione.rows.first.cassa_edile).to eq(400)
      end

      it "non altera le sezioni senza equivalente Cassa Edile" do
        expect(result.nazionalita.map(&:count)).to eq(
          Statistics::NationalityBreakdown.call(zoning: zoning, anno: "2026", mese: "Giugno").map(&:count)
        )
      end
    end

    context "quando manca il dato Cassa Edile per l'anno precedente" do
      before do
        create(:integration_fillea, zoning: zoning, year: "2026", subscribers_ce: 400)
      end

      it "non si blocca e lascia l'anno precedente non corretto" do
        expect(result).to be_success
        expect(result.count_precedente).to eq(3) # nessuna correzione applicata
        expect(result.count_anno).to eq(402)
      end
    end
  end
end
