require "rails_helper"

RSpec.describe Statistics::ProvisionalRevocationBreakdown do
  let(:zoning) { create(:zoning) }

  subject(:rows) { described_class.call(zoning: zoning, anno: "2026", mese: "Giugno") }

  it "restituisce una riga per Provvisorie e una per Revoche, nell'ordine atteso" do
    expect(rows.map(&:tipologia)).to eq(%w[Provvisorie Revoche])
  end

  it "conta le pratiche provvisorie dal campo provvisoria = SI e calcola la percentuale sul totale iscritti" do
    create_list(:import, 3, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", provvisoria: "SI")
    create_list(:import, 7, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", provvisoria: "NO")

    provvisorie = rows.find { |row| row.tipologia == "Provvisorie" }
    expect(provvisorie.count).to eq(3)
    expect(provvisorie.percentuale).to be_within(0.01).of(30.0)
  end

  it "conta le revoche dal campo motivo_cessazione_iscrizione = Revoca e calcola la percentuale sul totale iscritti" do
    create_list(:import, 2, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", motivo_cessazione_iscrizione: "Revoca")
    create_list(:import, 8, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", motivo_cessazione_iscrizione: "Dimissioni")

    revoche = rows.find { |row| row.tipologia == "Revoche" }
    expect(revoche.count).to eq(2)
    expect(revoche.percentuale).to be_within(0.01).of(20.0)
  end

  it "restituisce percentuale nil quando non ci sono iscritti" do
    provvisorie = rows.find { |row| row.tipologia == "Provvisorie" }
    expect(provvisorie.count).to eq(0)
    expect(provvisorie.percentuale).to be_nil
  end

  it "non compara con l'anno precedente e ignora record di altri anni" do
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2025",
      mese_di_riferimento: "Giugno", provvisoria: "SI")
    create(:import, azzonamento_di_riferimento: zoning, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", provvisoria: "SI")

    provvisorie = rows.find { |row| row.tipologia == "Provvisorie" }
    expect(provvisorie.count).to eq(1)
  end

  it "preferisce codice_azzonamento_completo quando l'azzonamento non ha importazioni dirette" do
    provincia = create(:zoning, codice_azzonamento: "GB", descrizione_azzonamento: "Gorizia")
    regionale = create(:zoning, codice_azzonamento: "G", descrizione_azzonamento: "FVG")
    create_list(:import, 2, azzonamento_di_riferimento: regionale, anno_di_riferimento: "2026",
      mese_di_riferimento: "Giugno", provvisoria: "SI", codice_azzonamento_completo: "GB001")

    righe = described_class.call(zoning: provincia, anno: "2026", mese: "Giugno")

    provvisorie = righe.find { |row| row.tipologia == "Provvisorie" }
    expect(provvisorie.count).to eq(2)
  end
end
