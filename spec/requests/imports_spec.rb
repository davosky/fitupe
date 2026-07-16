require "rails_helper"

RSpec.describe "Imports", type: :request do
  let(:zoning) { create(:zoning) }
  let(:csv_path) { Rails.root.join("spec/fixtures/files/import_sample.csv") }
  let(:uploaded_file) { fixture_file_upload(csv_path, "text/csv") }
  let(:valid_params) do
    { import_form: { file: uploaded_file, zoning_id: zoning.id, anno: "2026", mese: "Giugno" } }
  end

  after { FileUtils.rm_rf(ImportForm::UPLOADS_DIR) }

  def stored_path_from(body)
    body[/value="([^"]+)" name="import_form\[stored_path\]"/, 1]
  end

  describe "GET /imports/:id" do
    it "mostra lo stato iniziale quando il job non ha ancora trasmesso nulla" do
      sign_in create(:user, :admin)
      get import_path("un-token-qualsiasi")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("turbo-cable-stream-source")
      expect(response.body).to include('id="import_progress"')
      expect(response.body).to include("0%")
    end

    it "recupera dalla cache lo stato più recente, anche se il job ha già finito" do
      sign_in create(:user, :admin)
      Rails.cache.write("import_progress_già-completato", { count: 42 })
      get import_path("già-completato")
      expect(response.body).to include("42 record importati")
    end
  end

  describe "GET /imports/new" do
    it "nega l'accesso a un utente regular" do
      sign_in create(:user, :regular)
      get new_import_path
      expect(response).to redirect_to(root_path)
    end

    it "consente l'accesso a un admin" do
      sign_in create(:user, :admin)
      get new_import_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /imports" do
    before { sign_in create(:user, :manager) }

    it "mostra gli errori con dati non validi" do
      post imports_path, params: { import_form: { zoning_id: "", anno: "", mese: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accoda il job di importazione con dati validi e reindirizza alla pagina di avanzamento" do
      expect { post imports_path, params: valid_params }
        .to have_enqueued_job(ImportCsvJob).with(
          path: a_string_starting_with(ImportForm::UPLOADS_DIR.to_s), zoning_id: zoning.id, anno: "2026",
          mese: "Giugno", overwrite: false, token: anything
        )

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to match(%r{/imports/})
    end

    context "quando esiste già un'importazione per lo stesso azzonamento/anno/mese" do
      before { create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026", mese_di_riferimento: "Giugno") }

      it "chiede conferma senza accodare alcun job, e persiste il file caricato" do
        expect { post imports_path, params: valid_params }.not_to have_enqueued_job(ImportCsvJob)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Esiste già un'importazione")

        stored_path = stored_path_from(response.body)
        expect(stored_path).to be_present
        expect(File.exist?(stored_path)).to be true
      end

      it "annulla la nuova importazione con resolution=keep e ripulisce il file temporaneo" do
        post imports_path, params: valid_params
        stored_path = stored_path_from(response.body)

        params = { import_form: { stored_path: stored_path, zoning_id: zoning.id, anno: "2026", mese: "Giugno",
          resolution: "keep" } }
        expect { post imports_path, params: params }.not_to have_enqueued_job(ImportCsvJob)
        expect(response).to redirect_to(new_import_path)
        expect(File.exist?(stored_path)).to be false
      end

      it "accoda il job con overwrite=true riusando il file già caricato" do
        post imports_path, params: valid_params
        stored_path = stored_path_from(response.body)

        params = { import_form: { stored_path: stored_path, zoning_id: zoning.id, anno: "2026", mese: "Giugno",
          resolution: "overwrite" } }
        expect { post imports_path, params: params }
          .to have_enqueued_job(ImportCsvJob).with(
            path: stored_path, zoning_id: zoning.id, anno: "2026", mese: "Giugno", overwrite: true, token: anything
          )
      end
    end
  end
end
