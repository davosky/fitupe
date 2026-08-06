require "rails_helper"

RSpec.describe "LegendSpis", type: :request do
  describe "GET /legend_spis" do
    it "reindirizza al login se non autenticato" do
      get legend_spis_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get legend_spis_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un manager" do
      sign_in create(:user, :manager)
      get legend_spis_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /legend_spis" do
    it "crea una legenda SPI con dati validi" do
      sign_in create(:user, :admin)
      zoning = create(:zoning)

      expect {
        post legend_spis_path,
          params: { legend_spi: { zoning_id: zoning.id, year: "2026", month: "Gennaio", description: "<div>Testo</div>" } }
      }.to change(LegendSpi, :count).by(1)

      expect(response).to redirect_to(legend_spis_path)
    end

    it "non crea la legenda SPI con dati non validi" do
      sign_in create(:user, :admin)

      expect {
        post legend_spis_path, params: { legend_spi: { year: "", month: "", description: "" } }
      }.not_to change(LegendSpi, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /legend_spis/:id" do
    it "elimina la legenda SPI" do
      sign_in create(:user, :admin)
      legend_spi = create(:legend_spi)

      expect { delete legend_spi_path(legend_spi) }.to change(LegendSpi, :count).by(-1)
    end
  end
end
