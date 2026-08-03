module ImportSpis
  class SchemaSyncService
    def self.call(headers)
      new(headers).call
    end

    def initialize(headers)
      @columns = headers.compact.map { |header| Imports::HeaderNormalizer.call(header) } - ImportSpi::IGNORED_COLUMNS
    end

    def call
      missing_columns.each { |column| add_column(column) }
      ImportSpi.reset_column_information if missing_columns.any?
    end

    private

    def missing_columns
      @missing_columns ||= @columns - ImportSpi.column_names
    end

    def add_column(column)
      return if ActiveRecord::Base.connection.column_exists?(:imports_spi, column)

      ActiveRecord::Base.connection.add_column(:imports_spi, column, column_type(column))
    end

    def column_type(column)
      return :date if ImportSpi::DATE_COLUMNS.include?(column)
      return :decimal if ImportSpi::DECIMAL_COLUMNS.include?(column)

      :string
    end
  end
end
