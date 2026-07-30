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

  describe "#regionale?" do
    it "è vero per un codice azzonamento di una sola lettera" do
      expect(build(:zoning, codice_azzonamento: "G")).to be_regionale
    end

    it "è falso per un codice azzonamento provinciale" do
      expect(build(:zoning, codice_azzonamento: "GB")).not_to be_regionale
    end
  end

  describe ".comprensori_di" do
    it "trova i comprensori sotto un azzonamento regionale, in ordine di codice" do
      regionale = create(:zoning, codice_azzonamento: "G")
      pordenone = create(:zoning, codice_azzonamento: "GC")
      gorizia = create(:zoning, codice_azzonamento: "GB")
      create(:zoning, codice_azzonamento: "H")

      expect(Zoning.comprensori_di(regionale)).to eq([ gorizia, pordenone ])
    end
  end
end
