FactoryBot.define do
  factory :import_spi do
    association :azzonamento_di_riferimento, factory: :zoning
    anno_di_riferimento { "2026" }
    mese_di_riferimento { "Giugno" }
    cognome { "Verdi" }
    nome { "Anna" }
    codice_fiscale { "VRDNNA80A41H501U" }
  end
end
