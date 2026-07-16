FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    password { "password12345" }
    password_confirmation { "password12345" }
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
