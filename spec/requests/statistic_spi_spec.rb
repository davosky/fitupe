require "rails_helper"

RSpec.describe "StatisticSpi", type: :request do
  describe "GET /statistic_spi" do
    it "reindirizza al login se non autenticato" do
      get statistic_spi_index_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "con un azzonamento regionale" do
      let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "Friuli Venezia Giulia") }

      before do
        create_list(:import_spi, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
          mese_di_riferimento: "Giugno")
        create_list(:import_spi, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno")
        sign_in create(:user, :manager)
        get statistic_spi_index_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra le sezioni Iscritti e Deleghe" do
        expect(response.body).to include("Iscritti")
        expect(response.body).to include("Deleghe")
      end

      it "mostra la descrizione dell'azzonamento" do
        expect(response.body).to include("Friuli Venezia Giulia")
      end

      it "non mostra le sezioni successive a Regionale/Comprensori presenti nella Statistiche base" do
        expect(response.body).not_to include("Categorie")
        expect(response.body).not_to include("Tipologie Iscrizione")
      end
    end

    context "con un azzonamento provinciale" do
      let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Pordenone") }

      before do
        create_list(:import_spi, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
          mese_di_riferimento: "Giugno")
        create_list(:import_spi, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno")
        sign_in create(:user, :manager)
        get statistic_spi_index_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra la descrizione dell'azzonamento" do
        expect(response.body).to include("Pordenone")
      end

      it "non mostra la sezione Comprensori" do
        expect(response.body).not_to include("Comprensori")
      end
    end

    context "senza dati per il periodo scelto" do
      let(:zoning) { create(:zoning) }

      before do
        sign_in create(:user, :manager)
        get statistic_spi_index_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra un messaggio di avviso" do
        expect(response.body).to include("Non ci sono dati")
      end
    end
  end
end
