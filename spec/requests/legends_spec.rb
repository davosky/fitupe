require "rails_helper"

RSpec.describe "Legends", type: :request do
  describe "GET /legends" do
    it "reindirizza al login se non autenticato" do
      get legends_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get legends_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un manager" do
      sign_in create(:user, :manager)
      get legends_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /legends" do
    it "crea una legenda con dati validi" do
      sign_in create(:user, :admin)
      zoning = create(:zoning)

      expect {
        post legends_path,
          params: { legend: { zoning_id: zoning.id, year: "2026", month: "Gennaio", description: "<div>Testo</div>" } }
      }.to change(Legend, :count).by(1)

      expect(response).to redirect_to(legends_path)
    end

    it "non crea la legenda con dati non validi" do
      sign_in create(:user, :admin)

      expect {
        post legends_path, params: { legend: { year: "", month: "", description: "" } }
      }.not_to change(Legend, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /legends/:id" do
    it "elimina la legenda" do
      sign_in create(:user, :admin)
      legend = create(:legend)

      expect { delete legend_path(legend) }.to change(Legend, :count).by(-1)
    end
  end
end
