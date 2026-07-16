require "rails_helper"

RSpec.describe ImportCsvJob, type: :job do
  let(:zoning) { create(:zoning) }
  let(:args) do
    { path: "irrilevante.csv", zoning_id: zoning.id, anno: "2026", mese: "Giugno", overwrite: false, token: "tok-123" }
  end

  it "trasmette il progresso e poi il conteggio finale in caso di successo" do
    allow(Imports::CsvImporterService).to receive(:call) do |progress:, **|
      progress.call(50)
      12
    end

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with("import_progress_tok-123", target: "import_progress", partial: "imports/progress", locals: { percent: 50 })
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with("import_progress_tok-123", target: "import_progress", partial: "imports/progress", locals: { count: 12 })

    described_class.perform_now(**args)

    expect(Rails.cache.read("import_progress_tok-123")).to eq(count: 12)
  end

  it "trasmette un messaggio di errore se il servizio solleva un'eccezione" do
    allow(Imports::CsvImporterService).to receive(:call).and_raise(StandardError, "file non leggibile")

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with("import_progress_tok-123", target: "import_progress", partial: "imports/progress",
        locals: { error: "file non leggibile" })

    described_class.perform_now(**args)

    expect(Rails.cache.read("import_progress_tok-123")).to eq(error: "file non leggibile")
  end
end
