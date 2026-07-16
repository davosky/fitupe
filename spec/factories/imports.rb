FactoryBot.define do
  factory :import do
    association :azzonamento_di_riferimento, factory: :zoning
    anno_di_riferimento { "2026" }
    mese_di_riferimento { "Giugno" }
    cognome { "Rossi" }
    nome { "Mario" }
    codice_fiscale { "RSSMRA80A01H501U" }
  end
end
