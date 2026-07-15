require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to be_valid }

    it "richiede un username" do
      subject.username = nil
      expect(subject).not_to be_valid
    end

    it "richiede un username univoco (case insensitive)" do
      create(:user, username: "mario.rossi")
      subject.username = "Mario.Rossi"
      expect(subject).not_to be_valid
    end

    it "richiede una password alla creazione" do
      subject.password = nil
      subject.password_confirmation = nil
      expect(subject).not_to be_valid
    end

    it "richiede la conferma della password" do
      subject.password_confirmation = "altrapassword"
      expect(subject).not_to be_valid
    end
  end

  describe "autenticazione tramite username" do
    it "trova l'utente tramite find_for_database_authentication" do
      user = create(:user, username: "mario.rossi")
      expect(User.find_for_database_authentication(username: "mario.rossi")).to eq(user)
    end
  end

  describe "#full_name" do
    it "unisce nome e cognome" do
      user = build(:user, first_name: "Mario", last_name: "Rossi")
      expect(user.full_name).to eq("Mario Rossi")
    end
  end

  describe "scopes" do
    it ".admins ritorna solo gli utenti admin" do
      admin = create(:user, :admin)
      create(:user)
      expect(User.admins).to contain_exactly(admin)
    end
  end
end
