class IntegrationFillea < ApplicationRecord
  belongs_to :zoning

  validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
  validates :subscribers_ce, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :year, uniqueness: { scope: :zoning_id, message: "esiste già un'integrazione per questo azzonamento e anno" }
end
