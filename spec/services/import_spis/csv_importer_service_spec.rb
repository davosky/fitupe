require "rails_helper"

RSpec.describe ImportSpis::CsvImporterService do
  let(:csv_path) { Rails.root.join("spec/fixtures/files/import_spi_sample.csv").to_s }
  let(:zoning) { create(:zoning, codice_azzonamento: "G") }
  let(:other_zoning) { create(:zoning, codice_azzonamento: "H") }

  after { ImportSpi.reset_column_information }

  def import(zoning_id: zoning.id, anno: "2026", mese: "Giugno", overwrite: false, progress: ->(_p) { })
    described_class.call(path: csv_path, zoning_id: zoning_id, anno: anno, mese: mese, overwrite: overwrite,
      progress: progress)
  end

  it "importa tutte le righe dati del CSV" do
    count = import

    expect(count).to eq(3)
    expect(ImportSpi.count).to eq(3)
  end

  it "normalizza gli header in snake_case e valorizza le colonne" do
    import
    record = ImportSpi.find_by(codice_fiscale: "BNCMRA45D41H501Z")

    expect(record.cognome).to eq("BIANCHI")
    expect(record.categoria_sindacale).to eq("SPI")
  end

  it "esclude Utente Modifica e Data Modifica" do
    import

    expect(ImportSpi.column_names).not_to include("utente_modifica", "data_modifica")
  end

  it "converte in Date le colonne data note e in nil i valori vuoti" do
    import
    record = ImportSpi.find_by(codice_fiscale: "BNCMRA45D41H501Z")

    expect(record.data_nascita).to eq(Date.new(1945, 4, 1))
    expect(record.data_decesso).to be_nil
  end

  it "converte la virgola in punto per la colonna decimale Rata" do
    import
    con_rata = ImportSpi.find_by(codice_fiscale: "BNCMRA45D41H501Z")
    senza_rata = ImportSpi.find_by(codice_fiscale: "VRDNNA80A41H501U")

    expect(con_rata.rata).to eq(10.17)
    expect(senza_rata.rata).to be_nil
  end

  it "valorizza anno, mese e azzonamento di riferimento su ogni riga" do
    import(zoning_id: zoning.id, anno: "2026", mese: "Giugno")

    expect(ImportSpi.pluck(:anno_di_riferimento, :mese_di_riferimento, :azzonamento_di_riferimento_id).uniq)
      .to contain_exactly([ "2026", "Giugno", zoning.id ])
  end

  it "chiama la progress callback fino al 100%" do
    percentages = []

    import(progress: ->(p) { percentages << p })

    expect(percentages.last).to eq(100)
  end

  it "aggiunge dinamicamente le colonne nuove trovate nel CSV" do
    expect(ImportSpi.column_names).not_to include("nuovo_campo_sperimentale")

    rows = CSV.read(csv_path, headers: true, col_sep: ";", liberal_parsing: true)
    Tempfile.create([ "import_spi", ".csv" ]) do |file|
      CSV.open(file.path, "w", col_sep: ";") do |csv|
        csv << (rows.headers + [ "Nuovo Campo Sperimentale" ])
        rows.each { |row| csv << (row.fields + [ "Valore Test" ]) }
      end

      described_class.call(path: file.path, zoning_id: zoning.id, anno: "2026", mese: "Giugno", overwrite: false,
        progress: ->(_p) { })
    end

    expect(ImportSpi.column_names).to include("nuovo_campo_sperimentale")
    expect(ImportSpi.pluck(:nuovo_campo_sperimentale).uniq).to eq([ "Valore Test" ])
  end

  describe "overwrite scope" do
    before do
      import(zoning_id: zoning.id, anno: "2026", mese: "Giugno")
      import(zoning_id: other_zoning.id, anno: "2026", mese: "Giugno")
    end

    it "senza overwrite accumula i record per lo stesso periodo/azzonamento" do
      import(zoning_id: zoning.id, anno: "2026", mese: "Giugno", overwrite: false)

      expect(ImportSpi.where(azzonamento_di_riferimento_id: zoning.id).count).to eq(6)
    end

    it "con overwrite sostituisce solo i record dello stesso azzonamento/anno/mese" do
      import(zoning_id: zoning.id, anno: "2026", mese: "Giugno", overwrite: true)

      expect(ImportSpi.where(azzonamento_di_riferimento_id: zoning.id).count).to eq(3)
      expect(ImportSpi.where(azzonamento_di_riferimento_id: other_zoning.id).count).to eq(3)
    end
  end
end
