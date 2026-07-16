require "rails_helper"

RSpec.describe ZoningPolicy do
  subject(:policy) { described_class.new(user, Zoning.new) }

  context "con un utente regular" do
    let(:user) { build(:user, :regular) }

    it { expect(policy.index?).to be false }
    it { expect(policy.create?).to be false }
  end

  context "con un utente manager" do
    let(:user) { build(:user, :manager) }

    it { expect(policy.index?).to be true }
    it { expect(policy.create?).to be true }
  end

  context "con un utente admin" do
    let(:user) { build(:user, :admin) }

    it { expect(policy.index?).to be true }
    it { expect(policy.destroy?).to be true }
  end

  describe "Scope" do
    it "ritorna tutti gli azzonamenti per admin/manager, nessuno per gli altri" do
      create(:zoning)
      admin_scope = ZoningPolicy::Scope.new(build(:user, :admin), Zoning.all).resolve
      regular_scope = ZoningPolicy::Scope.new(build(:user, :regular), Zoning.all).resolve

      expect(admin_scope.count).to eq(1)
      expect(regular_scope.count).to eq(0)
    end
  end
end
