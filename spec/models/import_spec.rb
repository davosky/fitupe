require "rails_helper"

RSpec.describe Import, type: :model do
  describe "validazioni" do
    subject { build(:import) }

    it { is_expected.to be_valid }

    it "richiede l'anno di riferimento" do
      subject.anno_di_riferimento = nil
      expect(subject).not_to be_valid
    end

    it "richiede il mese di riferimento" do
      subject.mese_di_riferimento = nil
      expect(subject).not_to be_valid
    end

    it "richiede l'azzonamento di riferimento" do
      subject.azzonamento_di_riferimento = nil
      expect(subject).not_to be_valid
    end
  end

  describe "DATE_COLUMNS" do
    it "elenca solo le colonne data note" do
      expect(Import::DATE_COLUMNS).to include("data_nascita", "data_contabilizzazione_tessera")
      expect(Import::DATE_COLUMNS).not_to include("cognome")
    end
  end

  describe "IGNORED_COLUMNS" do
    it "esclude i campi Utente Modifica e Data Modifica" do
      expect(Import::IGNORED_COLUMNS).to contain_exactly("utente_modifica", "data_modifica")
    end
  end
end
