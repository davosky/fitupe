module Imports
  class SchemaSyncService
    def self.call(headers)
      new(headers).call
    end

    def initialize(headers)
      @columns = headers.compact.map { |header| HeaderNormalizer.call(header) } - Import::IGNORED_COLUMNS
    end

    def call
      missing_columns.each { |column| add_column(column) }
      Import.reset_column_information if missing_columns.any?
    end

    private

    def missing_columns
      @missing_columns ||= @columns - Import.column_names
    end

    def add_column(column)
      return if ActiveRecord::Base.connection.column_exists?(:imports, column)

      type = Import::DATE_COLUMNS.include?(column) ? :date : :string
      ActiveRecord::Base.connection.add_column(:imports, column, type)
    end
  end
end
