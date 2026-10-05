class Import < ApplicationRecord
  DATE_COLUMNS = %w[
    data_nascita data_decesso data_inizio_lavoro data_fine_lavoro
    data_inizio_iscrizione data_fine_iscrizione data_inizio_trattenuta
    data_fine_trattenuta data_contabilizzazione_tessera
  ].freeze

  IGNORED_COLUMNS = %w[utente_modifica data_modifica].freeze

  belongs_to :azzonamento_di_riferimento, class_name: "Zoning", inverse_of: :imports

  validates :anno_di_riferimento, :mese_di_riferimento, presence: true

  # La categoria sindacale è in "Categoria" o in "Categoria Sindacale" a
  # seconda dell'intestazione dell'export SinCGIL del mese (mai entrambe sulla
  # stessa riga): COALESCE le unisce nelle query che raggruppano per categoria.
  def self.categoria_sql
    column_names.include?("categoria_sindacale") ? "COALESCE(categoria_sindacale, categoria)" : "categoria"
  end
end
