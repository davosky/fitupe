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

  describe "GET /statistics/progression" do
    it "reindirizza al login se non autenticato" do
      get progression_statistics_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "con dati per entrambi gli anni" do
      let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }

      before do
        { "2025" => [ 4, 5 ], "2026" => [ 2, 3 ] }.each do |anno, (gennaio, febbraio)|
          create_list(:import, gennaio, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
            mese_di_riferimento: "Gennaio")
          create_list(:import, febbraio, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
            mese_di_riferimento: "Febbraio")
        end
        sign_in create(:user)
        get progression_statistics_path(annual_progression_form: { zoning_id: zoning.id, anno: "2026" })
      end

      it "mostra le tabelle dei due anni e la differenza di crescita" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Differenza di Crescita 2025-2026")
        expect(response.body).to include("Crescita % 2025")
        expect(response.body).to match(/text-success">\s*25,00%/)
      end
    end
  end

  describe "GET /statistics/progression_categories" do
    it "reindirizza al login se non autenticato" do
      get progression_categories_statistics_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "con dati per entrambi gli anni" do
      let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }

      before do
        { "2025" => [ 4, 5 ], "2026" => [ 2, 3 ] }.each do |anno, (gennaio, febbraio)|
          create_list(:import, gennaio, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
            mese_di_riferimento: "Gennaio", categoria: "FIOM")
          create_list(:import, febbraio, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
            mese_di_riferimento: "Febbraio", categoria: "FIOM")
        end
        sign_in create(:user)
        get progression_categories_statistics_path(annual_progression_form: { zoning_id: zoning.id, anno: "2026" })
      end

      it "mostra le categorie e la differenza di crescita" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Progressione Annuale Categorie", "FIOM")
        expect(response.body).to match(/text-success">\s*25,00%/)
      end
    end
  end

  describe "GET /statistics/progression_categories_monthly" do
    it "reindirizza al login se non autenticato" do
      get progression_categories_monthly_statistics_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "con dati per entrambi gli anni" do
      let(:zoning) { create(:zoning, codice_azzonamento: "GA", descrizione_azzonamento: "Trieste") }

      before do
        { "2025" => [ 4, 5 ], "2026" => [ 3, 2 ] }.each do |anno, (gennaio, febbraio)|
          create_list(:import, gennaio, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
            mese_di_riferimento: "Gennaio", categoria: "FIOM")
          create_list(:import, febbraio, azzonamento_di_riferimento: zoning, anno_di_riferimento: anno,
            mese_di_riferimento: "Febbraio", categoria: "FIOM")
        end
        sign_in create(:user)
        get progression_categories_monthly_statistics_path(
          annual_progression_form: { zoning_id: zoning.id, anno: "2026" }
        )
      end

      it "mostra progressione e regressione per categoria" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Progressione Mensile Categorie", "FIOM")
        expect(response.body).to match(/text-danger">\s*-1/)
        expect(response.body).to match(/text-success">\s*\+1/)
      end
    end
  end
end
