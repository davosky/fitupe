FactoryBot.define do
  factory :integration_fillea do
    association :zoning
    year { "2026" }
    subscribers_ce { 42 }
  end
end
