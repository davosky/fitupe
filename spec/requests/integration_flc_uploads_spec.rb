require "rails_helper"

RSpec.describe "IntegrationFlcUploads", type: :request do
  let(:zoning) { create(:zoning) }
  let(:csv_path) { Rails.root.join("spec/fixtures/files/anagrafe_flc_sample.csv") }

  describe "GET /integration_flc_uploads/new" do
    it "reindirizza al login se non autenticato" do
      get new_integration_flc_upload_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get new_integration_flc_upload_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un manager" do
      sign_in create(:user, :manager)
      get new_integration_flc_upload_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /integration_flc_uploads" do
    it "crea l'integrazione FLC quando l'importazione SinCGIL esiste" do
      sign_in create(:user, :admin)
      create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno",
        categoria_sindacale: "FLC", codice_fiscale: "RSSMRA80A01H501U")

      expect {
        post integration_flc_uploads_path, params: {
          integration_flc_upload_form: {
            file: fixture_file_upload(csv_path, "text/csv"),
            zoning_id: zoning.id, year: "2026", month: "Giugno"
          }
        }
      }.to change(IntegrationFlc, :count).by(1)

      integration_flc = IntegrationFlc.last
      expect(integration_flc.subscribers_af).to eq(2)
      expect(response).to redirect_to(integration_flc_path(integration_flc))
    end

    it "non crea l'integrazione se manca l'importazione SinCGIL" do
      sign_in create(:user, :admin)

      expect {
        post integration_flc_uploads_path, params: {
          integration_flc_upload_form: {
            file: fixture_file_upload(csv_path, "text/csv"),
            zoning_id: zoning.id, year: "2026", month: "Giugno"
          }
        }
      }.not_to change(IntegrationFlc, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "non crea l'integrazione con dati del form non validi" do
      sign_in create(:user, :admin)

      expect {
        post integration_flc_uploads_path, params: { integration_flc_upload_form: { year: "", month: "" } }
      }.not_to change(IntegrationFlc, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
