require "rails_helper"

RSpec.describe IntegrationFlc, type: :model do
  describe "validazioni" do
    let(:zoning) { create(:zoning) }
    subject { build(:integration_flc, zoning: zoning) }

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

    it "richiede gli iscritti Anagrafe FLC" do
      subject.subscribers_af = nil
      expect(subject).not_to be_valid
    end

    it "non accetta iscritti Anagrafe FLC negativi" do
      subject.subscribers_af = -1
      expect(subject).not_to be_valid
    end

    it "richiede una combinazione univoca di azzonamento, anno e mese" do
      create(:integration_flc, zoning: zoning, year: "2026", month: "01")
      subject.year = "2026"
      subject.month = "01"
      expect(subject).not_to be_valid
    end
  end
end
