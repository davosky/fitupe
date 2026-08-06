module StatisticSpi
  # Conta le cessazioni (motivo_cessazione_iscrizione tra un elenco fisso di
  # motivi rilevanti, altri valori come "Scadenza versamento diretto" esclusi)
  # per motivo, a livello regionale e per comprensorio. Come
  # TipologieDelegaBreakdown nessuna riconciliazione DISTINCT ON e' necessaria
  # (ogni cessazione e' gia' un record additivo). A differenza sua pero' le
  # percentuali non sono calcolate sul totale delle cessazioni stesse, ma sul
  # totale deleghe del periodo: le cessazioni sono un sottoinsieme delle
  # deleghe, non le esauriscono.
  class CessazioniBreakdown
    ETICHETTE = [
      "Altra Motivazione Ente", "Cambio Situazione Pensionistica", "Cessazione Posizione Pensionistica",
      "Chiusura Iscrizione Provvisoria", "Decesso", "Revoca"
    ].freeze

    Row = Struct.new(:zoning, :totali, :totale, :deleghe_totale, :percentuali, keyword_init: true)
    Result = Struct.new(:totale, :comprensori, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      if @zoning.regionale?
        Result.new(totale: build_row(@zoning, merge_counts(counts_by_comprensorio.values), deleghe_by_comprensorio.values.sum),
          comprensori: province_zonings.map { |zoning| build_row(zoning, counts_by_comprensorio[zoning.codice_azzonamento],
            deleghe_by_comprensorio[zoning.codice_azzonamento]) })
      else
        Result.new(totale: build_row(@zoning, counts_by_comprensorio[@zoning.codice_azzonamento],
          deleghe_by_comprensorio[@zoning.codice_azzonamento]), comprensori: [])
      end
    end

    private

    def build_row(zoning, counts, deleghe_totale)
      counts ||= {}
      deleghe_totale ||= 0
      totali = ETICHETTE.index_with { |etichetta| counts.fetch(etichetta, 0) }
      percentuali = totali.transform_values { |valore| deleghe_totale.zero? ? nil : (valore.to_f / deleghe_totale * 100) }

      Row.new(zoning:, totali:, totale: totali.values.sum, deleghe_totale:, percentuali:)
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

    def deleghe_by_comprensorio
      @deleghe_by_comprensorio ||= regional_scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
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
          CASE motivo_cessazione_iscrizione
            WHEN 'Altra motivazione Ente' THEN 'Altra Motivazione Ente'
            WHEN 'Cambio situazione pensionistica' THEN 'Cambio Situazione Pensionistica'
            WHEN 'Cessazione posizione pensionistica' THEN 'Cessazione Posizione Pensionistica'
            WHEN 'Chiusura Iscrizione Provvisoria' THEN 'Chiusura Iscrizione Provvisoria'
            WHEN 'Decesso' THEN 'Decesso'
            WHEN 'Revoca' THEN 'Revoca'
          END AS etichetta,
          COUNT(*) AS totale
        FROM base
        WHERE motivo_cessazione_iscrizione IN (
          'Altra motivazione Ente', 'Cambio situazione pensionistica', 'Cessazione posizione pensionistica',
          'Chiusura Iscrizione Provvisoria', 'Decesso', 'Revoca'
        )
        GROUP BY comprensorio, etichetta
      SQL
    end
  end
end
