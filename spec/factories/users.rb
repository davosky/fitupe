FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    password { "pAssword1234567" }
    password_confirmation { "pAssword1234567" }
    first_name { "Mario" }
    last_name { "Rossi" }
    gender { "M" }
    region { "FVG" }
    province { "FVG" }
    category { "CGIL" }

    trait :admin do
      admin { true }
    end

    trait :manager do
      manager { true }
    end

    trait :regular do
      regular { true }
    end
  end
end
