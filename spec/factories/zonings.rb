FactoryBot.define do
  factory :zoning do
    sequence(:codice_azzonamento) { |n| "Z#{n}" }
    descrizione_azzonamento { "Friuli Venezia Giulia" }
  end
end
