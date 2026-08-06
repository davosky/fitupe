FactoryBot.define do
  factory :legend_spi do
    association :zoning
    year { "2026" }
    month { "Gennaio" }
    description { "<div>Testo di legenda SPI.</div>" }
  end
end
