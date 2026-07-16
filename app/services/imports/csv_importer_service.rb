require "csv"

module Imports
  # Bulk-loads a large CSV via PostgreSQL COPY (much faster than batched
  # insert_all for tens of thousands of rows), reporting progress as it streams.
  class CsvImporterService
    PROGRESS_EVERY = 1000
    FIXED_COLUMNS = %i[azzonamento_di_riferimento_id anno_di_riferimento mese_di_riferimento created_at updated_at].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(path:, zoning_id:, anno:, mese:, overwrite:, progress: ->(_percent) { })
      @path = path
      @zoning_id = zoning_id
      @anno = anno
      @mese = mese
      @overwrite = overwrite
      @progress = progress
    end

    def call
      raw_headers = CSV.open(@path, col_sep: ";", liberal_parsing: true, &:shift)
      SchemaSyncService.call(raw_headers)
      @field_specs = build_field_specs(raw_headers)
      @columns = FIXED_COLUMNS + @field_specs.compact.map(&:first)
      total = [ count_data_rows, 1 ].max

      Import.transaction do
        delete_existing_scope if @overwrite
        copy_rows(total)
      end
    end

    private

    # Precomputes, once per file, the (column, is_date?) each CSV column maps
    # to — normalizing the header on every row would dominate the runtime.
    def build_field_specs(raw_headers)
      raw_headers.map do |header|
        next nil if header.nil?

        column = HeaderNormalizer.call(header)
        next nil if Import::IGNORED_COLUMNS.include?(column)

        [ column.to_sym, Import::DATE_COLUMNS.include?(column) ]
      end
    end

    def delete_existing_scope
      Import.where(azzonamento_di_riferimento_id: @zoning_id, anno_di_riferimento: @anno,
        mese_di_riferimento: @mese).delete_all
    end

    def copy_rows(total)
      imported = 0
      now = Time.current.iso8601
      connection = ActiveRecord::Base.connection.raw_connection

      connection.copy_data("COPY imports (#{@columns.join(',')}) FROM STDIN WITH (FORMAT csv)") do
        CSV.foreach(@path, headers: true, col_sep: ";", liberal_parsing: true) do |row|
          connection.put_copy_data(copy_line(row.fields, now))
          imported += 1
          @progress.call(percent(imported, total)) if (imported % PROGRESS_EVERY).zero?
        end
      end

      @progress.call(100)
      imported
    end

    def copy_line(fields, now)
      values = [ @zoning_id, @anno, @mese, now, now ]

      fields.each_with_index do |value, index|
        spec = @field_specs[index]
        next if spec.nil?

        _column, is_date = spec
        value = value&.strip.presence
        values << (is_date ? parse_date(value) : value)
      end

      CSV.generate_line(values, row_sep: "\n")
    end

    def parse_date(value)
      return nil if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def percent(imported, total)
      [ (imported * 100.0 / total).round, 99 ].min
    end

    def count_data_rows
      File.foreach(@path).count - 1
    end
  end
end
