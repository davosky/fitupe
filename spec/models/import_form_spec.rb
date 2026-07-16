require "rails_helper"

RSpec.describe ImportForm, type: :model do
  let(:csv_path) { Rails.root.join("spec/fixtures/files/import_sample.csv") }
  let(:uploaded_file) { fixture_file_upload(csv_path, "text/csv") }
  let(:zoning) { create(:zoning) }

  subject(:form) do
    described_class.new(file: uploaded_file, zoning_id: zoning.id, anno: "2026", mese: "Giugno")
  end

  after { FileUtils.rm_rf(ImportForm::UPLOADS_DIR) }

  it { is_expected.to be_valid }

  it "richiede un anno a 4 cifre" do
    form.anno = "26"
    expect(form).not_to be_valid
  end

  it "richiede un mese tra quelli validi" do
    form.mese = "Vattelapesca"
    expect(form).not_to be_valid
  end

  it "richiede un file quando non c'è ancora un percorso salvato" do
    form.file = nil
    expect(form).not_to be_valid
    expect(form.errors[:file]).to be_present
  end

  it "richiede un file con estensione .csv" do
    form.file = fixture_file_upload(Rails.root.join("spec/rails_helper.rb"), "text/plain")
    expect(form).not_to be_valid
  end

  it "è valido senza file se è già presente uno stored_path" do
    form.file = nil
    form.stored_path = csv_path.to_s
    expect(form).to be_valid
  end

  describe "#zoning" do
    it "carica l'azzonamento corrispondente" do
      expect(form.zoning).to eq(zoning)
    end
  end

  describe "#resolved_path" do
    it "persiste il file caricato in un percorso stabile e lo ritorna" do
      path = form.resolved_path

      expect(File.exist?(path)).to be true
      expect(File.read(path)).to eq(File.read(csv_path))
      expect(form.stored_path).to eq(path)
    end

    it "riusa lo stored_path se già presente, senza toccare il file" do
      form.stored_path = csv_path.to_s
      form.file = nil

      expect(form.resolved_path).to eq(csv_path.to_s)
    end
  end
end
