module StatisticSpi
  # Conta le deleghe (record, non codici fiscali distinti) per tipologia_delega,
  # sia a livello regionale che per comprensorio. A differenza di
  # MultipleDelegationsBreakdown non serve riconciliazione DISTINCT ON: ogni
  # delega e' gia' un record additivo, quindi il totale regionale coincide
  # sempre con la somma dei comprensori.
  class TipologieDelegaBreakdown
    ETICHETTE = [ "Ordinaria", "Concomitante", "Invalidi Civili", "BreviManu", "Altro" ].freeze

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
      totali = ETICHETTE.index_with { |etichetta| counts.fetch(etichetta, 0) }
      totale = totali.values.sum
      percentuali = totali.transform_values { |valore| totale.zero? ? nil : (valore.to_f / totale * 100) }

      Row.new(zoning:, totali:, totale:, percentuali:)
    end

    def merge_counts(counts_list)
      counts_list.compact.each_with_object(Hash.new(0)) do |counts, merged|
        counts.each { |etichetta, valore| merged[etichetta] += valore }
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
        (counts[row["comprensorio"]] ||= {})[row["etichetta"]] = row["totale"].to_i
      end
    end

    def sql
      <<~SQL
        WITH base AS (#{regional_scope.to_sql})
        SELECT
          SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2) AS comprensorio,
          CASE tipologia_delega
            WHEN 'Ordinaria' THEN 'Ordinaria'
            WHEN 'Concomitante' THEN 'Concomitante'
            WHEN 'Invalidi civili' THEN 'Invalidi Civili'
            WHEN 'Pagamento Diretto (Brevi Manu)' THEN 'BreviManu'
            ELSE 'Altro'
          END AS etichetta,
          COUNT(*) AS totale
        FROM base
        GROUP BY comprensorio, etichetta
      SQL
    end
  end
end
