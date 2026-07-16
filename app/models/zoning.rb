class Zoning < ApplicationRecord
  has_many :imports, foreign_key: "azzonamento_di_riferimento_id", inverse_of: :azzonamento_di_riferimento,
    dependent: :restrict_with_error

  validates :codice_azzonamento, presence: true, uniqueness: true
  validates :descrizione_azzonamento, presence: true
end
