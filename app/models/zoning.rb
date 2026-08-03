class Zoning < ApplicationRecord
  has_many :imports, foreign_key: "azzonamento_di_riferimento_id", inverse_of: :azzonamento_di_riferimento,
    dependent: :restrict_with_error
  has_many :import_spis, class_name: "ImportSpi", foreign_key: "azzonamento_di_riferimento_id",
    inverse_of: :azzonamento_di_riferimento, dependent: :restrict_with_error
  has_many :integration_filleas, dependent: :restrict_with_error
  has_many :legends, dependent: :restrict_with_error

  scope :comprensori_di, lambda { |zoning|
    where("codice_azzonamento LIKE ? AND codice_azzonamento != ?", "#{zoning.codice_azzonamento}%",
      zoning.codice_azzonamento).order(:codice_azzonamento)
  }

  validates :codice_azzonamento, presence: true, uniqueness: true
  validates :descrizione_azzonamento, presence: true

  def regionale?
    codice_azzonamento.to_s.length == 1
  end
end
