require "rails_helper"

RSpec.describe "IntegrationFilleas", type: :request do
  describe "GET /integration_filleas" do
    it "reindirizza al login se non autenticato" do
      get integration_filleas_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get integration_filleas_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un manager" do
      sign_in create(:user, :manager)
      get integration_filleas_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /integration_filleas" do
    it "crea un'integrazione FILLEA con dati validi" do
      sign_in create(:user, :admin)
      zoning = create(:zoning)

      expect {
        post integration_filleas_path,
          params: { integration_fillea: { zoning_id: zoning.id, year: "2026", subscribers_ce: 10 } }
      }.to change(IntegrationFillea, :count).by(1)

      expect(response).to redirect_to(integration_filleas_path)
    end

    it "non crea l'integrazione con dati non validi" do
      sign_in create(:user, :admin)

      expect {
        post integration_filleas_path, params: { integration_fillea: { year: "", subscribers_ce: nil } }
      }.not_to change(IntegrationFillea, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /integration_filleas/:id" do
    it "elimina l'integrazione FILLEA" do
      sign_in create(:user, :admin)
      integration_fillea = create(:integration_fillea)

      expect { delete integration_fillea_path(integration_fillea) }.to change(IntegrationFillea, :count).by(-1)
    end
  end
end
