require "rails_helper"

RSpec.describe "Zonings", type: :request do
  describe "GET /zonings" do
    it "reindirizza al login se non autenticato" do
      get zonings_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get zonings_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un manager" do
      sign_in create(:user, :manager)
      get zonings_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /zonings" do
    it "crea un azzonamento con dati validi" do
      sign_in create(:user, :admin)

      expect {
        post zonings_path, params: { zoning: { codice_azzonamento: "G", descrizione_azzonamento: "Friuli Venezia Giulia" } }
      }.to change(Zoning, :count).by(1)

      expect(response).to redirect_to(zonings_path)
    end

    it "non crea l'azzonamento con dati non validi" do
      sign_in create(:user, :admin)

      expect {
        post zonings_path, params: { zoning: { codice_azzonamento: "", descrizione_azzonamento: "" } }
      }.not_to change(Zoning, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /zonings/:id" do
    it "elimina l'azzonamento" do
      sign_in create(:user, :admin)
      zoning = create(:zoning)

      expect { delete zoning_path(zoning) }.to change(Zoning, :count).by(-1)
    end
  end
end
