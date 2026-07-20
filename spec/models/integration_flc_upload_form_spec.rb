require "rails_helper"

RSpec.describe IntegrationFlcUploadForm, type: :model do
  let(:csv_path) { Rails.root.join("spec/fixtures/files/anagrafe_flc_sample.csv") }
  let(:uploaded_file) { fixture_file_upload(csv_path, "text/csv") }
  let(:zoning) { create(:zoning) }

  subject(:form) do
    described_class.new(file: uploaded_file, zoning_id: zoning.id, year: "2026", month: "Giugno")
  end

  it { is_expected.to be_valid }

  it "richiede l'azzonamento" do
    form.zoning_id = nil
    expect(form).not_to be_valid
  end

  it "richiede un anno a 4 cifre" do
    form.year = "26"
    expect(form).not_to be_valid
  end

  it "richiede un mese tra quelli validi" do
    form.month = "Vattelapesca"
    expect(form).not_to be_valid
  end

  it "richiede un file" do
    form.file = nil
    expect(form).not_to be_valid
    expect(form.errors[:file]).to be_present
  end

  it "richiede un file con estensione .csv" do
    form.file = fixture_file_upload(Rails.root.join("spec/rails_helper.rb"), "text/plain")
    expect(form).not_to be_valid
  end

  describe "#zoning" do
    it "carica l'azzonamento corrispondente" do
      expect(form.zoning).to eq(zoning)
    end
  end
end
