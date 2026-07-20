require "csv"

module IntegrationFlcs
  # Parses an Anagrafe FLC extract into the set of codici fiscali it contains.
  # The exact export format (delimiter, exact header wording) isn't fixed by
  # any known sample, so both are detected rather than assumed.
  class AnagrafeCsvParser
    class InvalidFile < StandardError; end

    def self.call(...)
      new(...).call
    end

    def initialize(file)
      @file = file
    end

    def call
      table = CSV.parse(content, headers: true, col_sep: delimiter, liberal_parsing: true)
      column = codice_fiscale_header(table.headers)

      table.filter_map { |row| row[column]&.strip&.upcase.presence }.to_set
    end

    private

    def content
      @content ||= @file.read.force_encoding("UTF-8").delete_prefix("﻿")
    end

    def delimiter
      first_line = content.each_line.first.to_s
      first_line.count(";") > first_line.count(",") ? ";" : ","
    end

    def codice_fiscale_header(headers)
      headers.find { |header| Imports::HeaderNormalizer.call(header) == "codice_fiscale" } ||
        raise(InvalidFile, "Il file CSV non contiene una colonna Codice Fiscale")
    end
  end
end
