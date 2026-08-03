class ImportSpi < ApplicationRecord
  self.table_name = "imports_spi"

  DATE_COLUMNS = %w[
    data_nascita data_decesso data_inizio_lavoro data_fine_lavoro
    data_inizio_iscrizione data_fine_iscrizione data_inizio_trattenuta
    data_fine_trattenuta data_contabilizzazione_tessera
  ].freeze

  DECIMAL_COLUMNS = %w[rata].freeze

  IGNORED_COLUMNS = %w[utente_modifica data_modifica].freeze

  belongs_to :azzonamento_di_riferimento, class_name: "Zoning", inverse_of: :import_spis

  validates :anno_di_riferimento, :mese_di_riferimento, presence: true
end
