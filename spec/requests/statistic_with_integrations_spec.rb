require "rails_helper"

RSpec.describe "StatisticWithIntegrations", type: :request do
  describe "GET /statistic_with_integrations" do
    it "reindirizza al login se non autenticato" do
      get statistic_with_integrations_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "usa il form condiviso con Statistiche ma inviandolo a Statistiche Con Integrazioni" do
      sign_in create(:user)
      get statistic_with_integrations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Statistiche Con Integrazioni")
      expect(response.body).to include(%(action="#{statistic_with_integrations_path}"))
    end
  end
end
