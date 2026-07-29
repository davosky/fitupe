require "administrate/base_dashboard"

class LegendDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    zoning: Field::BelongsTo,
    year: Field::String,
    month: Field::String,
    description: Field::RichText,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    zoning
    year
    month
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    zoning
    year
    month
    description
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    zoning
    year
    month
    description
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  # def display_resource(legend)
  #   "Legend ##{legend.id}"
  # end
end
