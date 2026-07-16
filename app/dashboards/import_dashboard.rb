require "administrate/base_dashboard"

class ImportDashboard < Administrate::BaseDashboard
  def self.field_type_for(column)
    return Field::Number if column == "id"
    return Field::DateTime if %w[created_at updated_at].include?(column)
    return Field::Date if Import::DATE_COLUMNS.include?(column)

    Field::String
  end

  # `imports` gets new columns at runtime whenever the CSV export from SinCGIL
  # introduces a field we haven't seen (see Imports::SchemaSyncService), so the
  # attribute list is built from the live schema instead of a hardcoded hash —
  # this way new fields show up here automatically.
  ATTRIBUTE_TYPES = Import.column_names.each_with_object({}) { |column, types|
    next if column == "azzonamento_di_riferimento_id"

    types[column.to_sym] = field_type_for(column)
  }.merge(azzonamento_di_riferimento: Field::BelongsTo).freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  COLLECTION_ATTRIBUTES = %i[
    id
    cognome
    nome
    codice_fiscale
    anno_di_riferimento
    mese_di_riferimento
    azzonamento_di_riferimento
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = (ATTRIBUTE_TYPES.keys - %i[id created_at updated_at]).freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  COLLECTION_FILTERS = {}.freeze
end
