require "rails_helper"

RSpec.describe LegendPolicy do
  subject(:policy) { described_class.new(user, Legend.new) }

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
    it "ritorna tutte le legende per admin/manager, nessuna per gli altri" do
      create(:legend)
      admin_scope = LegendPolicy::Scope.new(build(:user, :admin), Legend.all).resolve
      regular_scope = LegendPolicy::Scope.new(build(:user, :regular), Legend.all).resolve

      expect(admin_scope.count).to eq(1)
      expect(regular_scope.count).to eq(0)
    end
  end
end
