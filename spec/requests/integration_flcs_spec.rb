require "rails_helper"

RSpec.describe "IntegrationFlcs", type: :request do
  describe "GET /integration_flcs" do
    it "reindirizza al login se non autenticato" do
      get integration_flcs_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get integration_flcs_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un manager" do
      sign_in create(:user, :manager)
      get integration_flcs_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /integration_flcs" do
    it "crea un'integrazione FLC con dati validi" do
      sign_in create(:user, :admin)
      zoning = create(:zoning)

      expect {
        post integration_flcs_path,
          params: { integration_flc: { zoning_id: zoning.id, year: "2026", month: "Gennaio", subscribers_af: 10 } }
      }.to change(IntegrationFlc, :count).by(1)

      expect(response).to redirect_to(integration_flcs_path)
    end

    it "non crea l'integrazione con dati non validi" do
      sign_in create(:user, :admin)

      expect {
        post integration_flcs_path, params: { integration_flc: { year: "", month: "", subscribers_af: nil } }
      }.not_to change(IntegrationFlc, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /integration_flcs/:id" do
    it "elimina l'integrazione FLC" do
      sign_in create(:user, :admin)
      integration_flc = create(:integration_flc)

      expect { delete integration_flc_path(integration_flc) }.to change(IntegrationFlc, :count).by(-1)
    end
  end
end
