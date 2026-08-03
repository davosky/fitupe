module StatisticSpi
  # Come Statistics::TotalMembersComparison ma limitato a Regionale/Comprensori
  # e sdoppiato su due metriche: iscritti (codici fiscali distinti, riconciliati
  # per comprensorio) e deleghe (conteggio record, gia' additivo).
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :iscritti_totale, :iscritti_comprensori,
      :deleghe_totale, :deleghe_comprensori, :error, keyword_init: true) do
      def success?
        error.blank?
      end
    end

    Row = Struct.new(:zoning, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      missing_years = [ @anno, @anno_precedente ].reject { |anno| scope_for(anno).exists? }
      return missing_data_result(missing_years) if missing_years.any?

      build_result
    end

    private

    def scope_for(anno)
      ZoningPeriodScope.call(zoning: @zoning, anno: anno, mese: @mese)
    end

    def build_result
      Result.new(
        zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        iscritti_totale: totale_row(:iscritti), iscritti_comprensori: comprensori_rows(:iscritti),
        deleghe_totale: totale_row(:deleghe), deleghe_comprensori: comprensori_rows(:deleghe)
      )
    end

    def totale_row(metric)
      build_row(@zoning, count_totale(@anno, metric), count_totale(@anno_precedente, metric))
    end

    def comprensori_rows(metric)
      return [] unless @zoning.regionale?

      counts_anno = count_by_comprensorio(@anno, metric)
      counts_precedente = count_by_comprensorio(@anno_precedente, metric)

      Zoning.comprensori_di(@zoning).map do |zoning|
        build_row(zoning, counts_anno[zoning.codice_azzonamento].to_i, counts_precedente[zoning.codice_azzonamento].to_i)
      end
    end

    def count_totale(anno, metric)
      scope = scope_for(anno)
      metric == :iscritti ? scope.distinct.count(:codice_fiscale) : scope.count(:codice_fiscale)
    end

    def count_by_comprensorio(anno, metric)
      scope = scope_for(anno)
      return ReconciledIscrittiByComprensorio.call(scope) if metric == :iscritti

      scope.group("SUBSTRING(codice_azzonamento_completo FROM 1 FOR 2)").count
    end

    def build_row(zoning, count_anno, count_precedente)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(zoning:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def missing_data_result(missing_years)
      Result.new(
        zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        error: "Non ci sono dati per #{@mese} #{missing_years.join(' e ')} " \
               "nell'azzonamento #{@zoning.descrizione_azzonamento}."
      )
    end
  end
end
