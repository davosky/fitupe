FactoryBot.define do
  factory :legend do
    association :zoning
    year { "2026" }
    month { "Gennaio" }
    description { "<div>Testo di legenda.</div>" }
  end
end
