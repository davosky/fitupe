module StatisticSpi
  # Distribuzione degli iscritti per fascia d'eta (classi per decine, es.
  # CINQUANTENNI/SESSANTENNI), a livello regionale e per comprensorio. Riusa
  # direttamente le fasce di Statistics::AgeBreakdown (generiche, non
  # specifiche degli Attivi) ma conta codice_fiscale distinti riconciliati per
  # comprensorio, come ReconciledIscrittiByComprensorio: un pensionato con piu'
  # deleghe in comprensori diversi non deve essere contato piu' volte.
  class AgeBreakdown
    BANDS = Statistics::AgeBreakdown::BANDS
    AGE_EXPR = Statistics::AgeBreakdown::AGE_EXPR

    Row = Struct.new(:zoning, :totali, :totale, :percentuali, keyword_init: true)
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
      totali = BANDS.to_h { |fascia, _upper| [ fascia, counts.fetch(fascia, 0) ] }
      totale = totali.values.sum
      percentuali = totali.transform_values { |valore| totale.zero? ? nil : (valore.to_f / totale * 100) }

      Row.new(zoning:, totali:, totale:, percentuali:)
    end

    def merge_counts(counts_list)
      counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
        counts.each { |fascia, valore| merged[fascia] += valore }
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
        (counts[row["comprensorio"]] ||= {})[row["fascia"]] = row["totale"].to_i
      end
    end

    def sql
      <<~SQL
        WITH base AS (#{regional_scope.to_sql}),
        persona AS (
          SELECT DISTINCT ON (codice_fiscale)
            codice_fiscale, data_nascita,
            SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio
          FROM base
          ORDER BY codice_fiscale, codice_azzonamento_completo
        )
        SELECT comprensorio, #{band_case_sql} AS fascia, COUNT(*) AS totale
        FROM persona
        WHERE data_nascita IS NOT NULL
        GROUP BY comprensorio, fascia
      SQL
    end

    def band_case_sql
      whens = BANDS.filter_map { |fascia, upper| "WHEN #{AGE_EXPR} < #{upper} THEN '#{fascia}'" if upper }
      "CASE #{whens.join(' ')} ELSE 'HIGHLANDERS' END"
    end
  end
end
