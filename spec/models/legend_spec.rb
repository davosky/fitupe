require "rails_helper"

RSpec.describe Legend, type: :model do
  describe "validazioni" do
    let(:zoning) { create(:zoning) }
    subject { build(:legend, zoning: zoning) }

    it { is_expected.to be_valid }

    it "richiede l'anno" do
      subject.year = nil
      expect(subject).not_to be_valid
    end

    it "richiede un anno a 4 cifre" do
      subject.year = "26"
      expect(subject).not_to be_valid
    end

    it "richiede il mese" do
      subject.month = nil
      expect(subject).not_to be_valid
    end

    it "richiede un mese valido" do
      subject.month = "Mese Inventato"
      expect(subject).not_to be_valid
    end

    it "richiede la descrizione" do
      subject.description = nil
      expect(subject).not_to be_valid
    end

    it "richiede una combinazione univoca di azzonamento, anno e mese" do
      create(:legend, zoning: zoning, year: "2026", month: "Gennaio")
      subject.year = "2026"
      subject.month = "Gennaio"
      expect(subject).not_to be_valid
    end
  end
end
