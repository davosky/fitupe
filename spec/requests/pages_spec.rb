require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    context "quando l'utente non è autenticato" do
      it "reindirizza al login" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "quando l'utente è autenticato" do
      it "risponde con successo" do
        sign_in create(:user)
        get root_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /credits" do
    context "quando l'utente è autenticato" do
      it "risponde con successo" do
        sign_in create(:user)
        get credits_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
