FactoryBot.define do
  factory :integration_flc do
    association :zoning
    year { "2026" }
    month { "01" }
    subscribers_af { 42 }
  end
end
