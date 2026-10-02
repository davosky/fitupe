module Statistics
  # Progressione mensile degli iscritti dell'anno scelto e del precedente, da
  # Gennaio fino all'ultimo mese disponibile dell'anno scelto, ricalibrata con
  # le integrazioni FILLEA/FLC come in Statistiche Con Integrazioni (un mese
  # senza dato di integrazione resta invariato, senza bloccare). La crescita %
  # di ciascun anno è (ultimo mese - Gennaio) / Gennaio.
  class AnnualProgression
    Result = Struct.new(:anno, :anno_precedente, :mesi, :rows_anno, :rows_precedente, :gaps, :error,
      keyword_init: true) do
      def success? = error.blank?
    end

    CORRECTIONS = [ StatisticWithIntegrations::FilleaCorrection, StatisticWithIntegrations::FlcCorrection ].freeze

    Row = Struct.new(:zoning, :counts, :crescita) { def label = zoning.descrizione_azzonamento }
    Gap = Struct.new(:zoning, :crescita_precedente, :crescita_anno, :differenza) { def label = zoning.descrizione_azzonamento }

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      return error_result("Non ci sono dati per il #{@anno}") if mesi.empty?
      return error_result("Non ci sono dati per Gennaio e #{mesi.last} #{@anno_precedente}") unless previous_complete?

      Result.new(anno: @anno, anno_precedente: @anno_precedente, mesi:, rows_anno: rows(@anno),
        rows_precedente: rows(@anno_precedente), gaps:)
    end

    private

    def mesi
      @mesi ||= begin
        last = ImportForm::MESI.rindex { |mese| scope(@zoning, @anno, mese).exists? }
        last ? ImportForm::MESI.first(last + 1) : []
      end
    end

    def previous_complete?
      [ mesi.first, mesi.last ].all? { |mese| scope(@zoning, @anno_precedente, mese).exists? }
    end

    # ponytail: ~3s sui dati reali FVG (count + integrazioni per comprensorio/mese), raggruppare se serve
    def rows(anno)
      (@rows ||= {})[anno] ||= zonings.map do |zoning|
        by_mese = scope(zoning, anno, mesi).group(:mese_di_riferimento).count
        counts = mesi.map { |mese| by_mese.fetch(mese, 0) + integrazione(zoning, anno, mese) }
        Row.new(zoning:, counts:, crescita: crescita(counts.first, counts.last))
      end
    end

    def gaps
      precedente = rows(@anno_precedente).index_by(&:zoning)
      rows(@anno).filter_map do |row|
        next unless chart_zonings.include?(row.zoning)

        prev = precedente[row.zoning].crescita
        differenza = row.crescita - prev if row.crescita && prev
        Gap.new(zoning: row.zoning, crescita_precedente: prev, crescita_anno: row.crescita, differenza:)
      end
    end

    # La regione somma le correzioni dei comprensori, come FilleaCorrection/FlcCorrection a livello regionale.
    def integrazione(zoning, anno, mese)
      return chart_zonings.sum { |comprensorio| integrazione(comprensorio, anno, mese) } unless chart_zonings.include?(zoning)

      (@integrazioni ||= {})[[ zoning, anno, mese ]] ||= CORRECTIONS.sum do |correction|
        result = correction.call(zoning:, anno:, mese:)
        result.success? ? result.total_diff : 0
      end
    end

    def crescita(primo, ultimo)
      return nil if primo.zero?

      (ultimo - primo).to_f / primo * 100
    end

    def zonings
      @zonings ||= [ @zoning, *chart_zonings ].uniq
    end

    def chart_zonings
      @chart_zonings ||= @zoning.regionale? ? Zoning.comprensori_di(@zoning).to_a.presence || [ @zoning ] : [ @zoning ]
    end

    def scope(zoning, anno, mese)
      ZoningPeriodScope.call(zoning:, anno:, mese:)
    end

    def error_result(message)
      Result.new(anno: @anno, anno_precedente: @anno_precedente,
        error: "#{message} nell'azzonamento #{@zoning.descrizione_azzonamento}.")
    end
  end
end
