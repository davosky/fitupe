require "rails_helper"

RSpec.describe ImportPolicy do
  subject(:policy) { described_class.new(user, Import) }

  context "con un utente regular" do
    let(:user) { build(:user, :regular) }

    it { expect(policy.manage?).to be false }
  end

  context "con un utente manager" do
    let(:user) { build(:user, :manager) }

    it { expect(policy.manage?).to be true }
  end

  context "con un utente admin" do
    let(:user) { build(:user, :admin) }

    it { expect(policy.manage?).to be true }
  end
end
