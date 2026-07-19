require "rails_helper"

RSpec.describe IntegrationFillea, type: :model do
  describe "validazioni" do
    let(:zoning) { create(:zoning) }
    subject { build(:integration_fillea, zoning: zoning) }

    it { is_expected.to be_valid }

    it "richiede l'anno" do
      subject.year = nil
      expect(subject).not_to be_valid
    end

    it "richiede un anno a 4 cifre" do
      subject.year = "26"
      expect(subject).not_to be_valid
    end

    it "richiede gli iscritti Cassa Edile" do
      subject.subscribers_ce = nil
      expect(subject).not_to be_valid
    end

    it "non accetta iscritti Cassa Edile negativi" do
      subject.subscribers_ce = -1
      expect(subject).not_to be_valid
    end

    it "richiede una combinazione univoca di azzonamento e anno" do
      create(:integration_fillea, zoning: zoning, year: "2026")
      subject.year = "2026"
      expect(subject).not_to be_valid
    end
  end
end
