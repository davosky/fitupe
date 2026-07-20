require "rails_helper"

RSpec.describe IntegrationFlcs::AnagrafeCsvParser do
  it "estrae i codici fiscali da un CSV separato da virgole" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/anagrafe_flc_sample.csv"), "text/csv")

    expect(described_class.call(file)).to eq(
      Set.new(%w[RSSMRA80A01H501U VRDGPP75M20L219K BNCLCU90T10F205X])
    )
  end

  it "estrae i codici fiscali da un CSV separato da punto e virgola" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/import_sample.csv"), "text/csv")

    expect(described_class.call(file)).not_to be_empty
  end

  it "solleva un errore se manca la colonna Codice Fiscale" do
    file = StringIO.new("Nome,Cognome\nMario,Rossi\n")

    expect { described_class.call(file) }.to raise_error(IntegrationFlcs::AnagrafeCsvParser::InvalidFile)
  end
end
