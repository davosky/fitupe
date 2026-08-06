class LegendSpi < ApplicationRecord
  belongs_to :zoning
  has_rich_text :description

  validates :year, presence: true, format: { with: /\A\d{4}\z/, message: "deve essere un anno a 4 cifre" }
  validates :month, presence: true, inclusion: { in: ImportForm::MESI }
  validates :description, presence: true
  validates :year, uniqueness: { scope: %i[zoning_id month], message: "esiste già una legenda SPI per questo azzonamento, anno e mese" }
end
