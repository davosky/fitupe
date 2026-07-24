require "rails_helper"

RSpec.describe "Statistics", type: :request do
  describe "GET /statistics" do
    it "reindirizza al login se non autenticato" do
      get statistics_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "con un azzonamento regionale" do
      let(:zoning) { create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "Friuli Venezia Giulia") }

      before do
        create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
          mese_di_riferimento: "Giugno")
        create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno")
        sign_in create(:user, :manager)
        get statistics_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra la descrizione dell'azzonamento al posto dell'etichetta statica" do
        expect(response.body).to include("Friuli Venezia Giulia")
      end

      it "usa l'icona regionale" do
        expect(response.body).to match(%r{statistic/regionale-\w+\.svg})
      end
    end

    context "con un azzonamento provinciale" do
      let(:zoning) { create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Pordenone") }

      before do
        create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
          mese_di_riferimento: "Giugno")
        create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno")
        sign_in create(:user, :manager)
        get statistics_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra la descrizione dell'azzonamento al posto dell'etichetta statica" do
        expect(response.body).to include("Pordenone")
      end

      it "usa l'icona dei comprensori" do
        expect(response.body).to match(%r{statistic/comprensori-\w+\.svg})
      end
    end

    context "con un incremento di iscritti" do
      let(:zoning) { create(:zoning) }

      before do
        create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
          mese_di_riferimento: "Giugno")
        create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno")
        sign_in create(:user, :manager)
        get statistics_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra iscritti e percentuale in grassetto verde" do
        expect(response.body).to match(/class="fs-5 fw-bold text-success">1<\/td>/)
        expect(response.body).to match(/class="fs-5 fw-bold text-success">\s*50,00%/)
      end
    end

    context "con un decremento di iscritti" do
      let(:zoning) { create(:zoning) }

      before do
        create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
          mese_di_riferimento: "Giugno")
        create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
          mese_di_riferimento: "Giugno")
        sign_in create(:user, :manager)
        get statistics_path(total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" })
      end

      it "mostra iscritti e percentuale in grassetto rosso" do
        expect(response.body).to match(/class="fs-5 fw-bold text-danger">-1<\/td>/)
        expect(response.body).to match(/class="fs-5 fw-bold text-danger">\s*-33,33%/)
      end
    end
  end
end
