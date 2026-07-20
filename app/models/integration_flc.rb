class IntegrationFlc < ApplicationRecord
  belongs_to :zoning

  validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
  validates :month, presence: true
  validates :subscribers_af, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :year, uniqueness: { scope: %i[zoning_id month], message: "esiste già un'integrazione per questo azzonamento, anno e mese" }
end
