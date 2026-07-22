module Statistics
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :error, keyword_init: true) do
      def success?
        error.blank?
      end
    end

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
      @anno_precedente = (anno.to_i - 1).to_s
    end

    def call
      missing_years = [ @anno, @anno_precedente ].reject { |anno| period_exists?(anno) }
      return missing_data_result(missing_years) if missing_years.any?

      build_result
    end

    private

    def period_exists?(anno)
      Import.exists?(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: anno, mese_di_riferimento: @mese)
    end

    def count_for(anno)
      Import.where(azzonamento_di_riferimento_id: @zoning.id, anno_di_riferimento: anno,
        mese_di_riferimento: @mese).count
    end

    def build_result
      count_anno = count_for(@anno)
      count_precedente = count_for(@anno_precedente)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente, count_anno:,
        count_precedente:, diff:, diff_percent:)
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
