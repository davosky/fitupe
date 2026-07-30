require "rails_helper"

RSpec.describe "StatisticWithIntegrationsPrints", type: :request do
  describe "GET /statistic_with_integrations_prints" do
    it "reindirizza al login se non autenticato" do
      get statistic_with_integrations_prints_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "da autenticato" do
      let(:zoning) { create(:zoning) }

      before { sign_in create(:user, :manager) }

      it "mostra la pagina anche senza parametri" do
        get statistic_with_integrations_prints_path

        expect(response).to have_http_status(:ok)
      end

      it "genera il PDF quando il form è valido" do
        create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025", mese_di_riferimento: "Giugno")
        create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno")

        get statistic_with_integrations_prints_path(
          total_members_form: { zoning_id: zoning.id, anno: "2026", mese: "Giugno" }, format: :pdf
        )

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/pdf")
      end

      it "reindirizza con un messaggio quando il form non è valido" do
        get statistic_with_integrations_prints_path(total_members_form: { anno: "2026" }, format: :pdf)

        expect(response).to redirect_to(statistic_with_integrations_prints_path)
      end
    end
  end
end
