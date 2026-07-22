require "rails_helper"

RSpec.describe TotalMembersForm, type: :model do
  let(:zoning) { create(:zoning) }

  subject(:form) { described_class.new(zoning_id: zoning.id, anno: "2026", mese: "Giugno") }

  it { is_expected.to be_valid }

  it "richiede un azzonamento" do
    form.zoning_id = nil
    expect(form).not_to be_valid
  end

  it "richiede un anno a 4 cifre" do
    form.anno = "26"
    expect(form).not_to be_valid
  end

  it "richiede un mese tra quelli validi" do
    form.mese = "Vattelapesca"
    expect(form).not_to be_valid
  end

  describe "#zoning" do
    it "carica l'azzonamento corrispondente" do
      expect(form.zoning).to eq(zoning)
    end
  end
end
