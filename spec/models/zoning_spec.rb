require "rails_helper"

RSpec.describe Zoning, type: :model do
  describe "validazioni" do
    subject { build(:zoning) }

    it { is_expected.to be_valid }

    it "richiede il codice azzonamento" do
      subject.codice_azzonamento = nil
      expect(subject).not_to be_valid
    end

    it "richiede un codice azzonamento univoco" do
      create(:zoning, codice_azzonamento: "G")
      subject.codice_azzonamento = "G"
      expect(subject).not_to be_valid
    end

    it "richiede la descrizione" do
      subject.descrizione_azzonamento = nil
      expect(subject).not_to be_valid
    end
  end

  describe "#imports" do
    it "impedisce la cancellazione se ci sono import collegati" do
      zoning = create(:zoning)
      create(:import, azzonamento_di_riferimento: zoning)

      expect(zoning.destroy).to be false
    end
  end
end
