module StatisticSpi
  # Assegna ogni codice_fiscale a UN SOLO comprensorio "primario" (il primo
  # alfabeticamente tra i codice_azzonamento_completo in cui compare), cosi'
  # il totale iscritti per comprensorio resta additivo rispetto al regionale.
  # Necessario per gli SPI (a differenza degli Attivi): uno stesso pensionato
  # puo' avere piu' deleghe in comprensori diversi (reversibilita', invalidita',
  # vedi .ai/Spi/pensionati.md), che altrimenti verrebbe contato una volta per
  # ciascun comprensorio in cui compare, gonfiando la somma rispetto al totale
  # regionale (COUNT DISTINCT codice_fiscale).
  class ReconciledIscrittiByComprensorio
    def self.call(scope) = new(scope).call

    def initialize(scope)
      @scope = scope
    end

    def call
      ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
        counts[row["comprensorio"]] = row["totale"].to_i
      end
    end

    private

    def sql
      <<~SQL
        WITH base AS (#{@scope.to_sql}),
        comprensorio_primario AS (
          SELECT DISTINCT ON (codice_fiscale)
            codice_fiscale,
            SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
          FROM base
          ORDER BY codice_fiscale, codice_azzonamento_completo
        )
        SELECT comprensorio, COUNT(*) AS totale
        FROM comprensorio_primario
        GROUP BY comprensorio
      SQL
    end
  end
end
