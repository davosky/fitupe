module StatisticSpi
  # Raggruppa i codice_fiscale con piu' di una delega (2-5, reversibilita'/
  # invalidita', vedi .ai/Spi/pensionati.md) per numero di occorrenze,
  # riconciliate per comprensorio con la stessa tecnica DISTINCT ON di
  # ReconciledIscrittiByComprensorio: ogni codice_fiscale viene assegnato a UN
  # SOLO comprensorio "primario" (il primo alfabeticamente tra quelli in cui
  # compare), calcolato pero' sulle occorrenze TOTALI sull'intera regione
  # (non solo dentro il comprensorio), cosi' la somma dei comprensori torna
  # sempre esattamente uguale al totale regionale.
  class MultipleDelegationsBreakdown
    OCCORRENZE = (2..5)

    Row = Struct.new(:zoning, :doppia, :tripla, :quadrupla, :quintupla, :totale, keyword_init: true)
    Result = Struct.new(:totale, :comprensori, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      if @zoning.regionale?
        Result.new(totale: build_row(@zoning, merge_counts(counts_by_comprensorio.values)),
          comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento]) })
      else
        Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
      end
    end

    private

    def build_row(zoning, counts)
      counts ||= {}
      doppia, tripla, quadrupla, quintupla = OCCORRENZE.map { |n| counts.fetch(n, 0) }

      Row.new(zoning:, doppia:, tripla:, quadrupla:, quintupla:, totale: doppia + tripla + quadrupla + quintupla)
    end

    def merge_counts(counts_list)
      counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
        counts.each { |numero, valore| merged[numero] += valore }
      end
    end

    def province_zonings
      Zoning.comprensori_di(@zoning)
    end

    def regional_zoning
      @zoning.regionale? ? @zoning : Zoning.find_by(codice_azzonamento: @zoning.codice_azzonamento[0])
    end

    def regional_scope
      return ImportSpi.none if regional_zoning.nil?

      ZoningPeriodScope.call(zoning: regional_zoning, anno: @anno, mese: @mese)
    end

    def counts_by_comprensorio
      @counts_by_comprensorio ||= ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, counts|
        (counts[row["comprensorio"]] ||= {})[row["numero_deleghe"].to_i] = row["numero_di_codici"].to_i
      end
    end

    def sql
      <<~SQL
        WITH base AS (#{regional_scope.to_sql}),
        occorrenze AS (
          SELECT codice_fiscale, COUNT(*) AS numero_deleghe
          FROM base
          GROUP BY codice_fiscale
        ),
        comprensorio_primario AS (
          SELECT DISTINCT ON (codice_fiscale)
            codice_fiscale,
            SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
          FROM base
          ORDER BY codice_fiscale, codice_azzonamento_completo
        )
        SELECT
          COALESCE(cp.comprensorio, 'N/D') AS comprensorio,
          o.numero_deleghe,
          COUNT(*) AS numero_di_codici
        FROM occorrenze o
        LEFT JOIN comprensorio_primario cp ON cp.codice_fiscale = o.codice_fiscale
        WHERE o.numero_deleghe BETWEEN #{OCCORRENZE.min} AND #{OCCORRENZE.max}
        GROUP BY comprensorio, o.numero_deleghe
      SQL
    end
  end
end
