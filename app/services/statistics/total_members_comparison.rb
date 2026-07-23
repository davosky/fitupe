module Statistics
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :comprensori, :error, keyword_init: true) do
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
      missing_years = [ @anno, @anno_precedente ].reject { |anno| period_exists?(@zoning, anno) }
      return missing_data_result(missing_years) if missing_years.any?

      build_result
    end

    private

    def period_exists?(zoning, anno)
      scope_for(zoning, anno).exists?
    end

    def count_for(zoning, anno)
      scope_for(zoning, anno).count
    end

    # Se non esiste alcuna importazione per l'azzonamento scelto (es. "GB"),
    # cerca un'importazione registrata sotto l'azzonamento superiore (es. "G")
    # e filtra i record tramite codice_azzonamento_completo.
    def scope_for(zoning, anno)
      exact_scope = Import.where(azzonamento_di_riferimento_id: zoning.id, anno_di_riferimento: anno,
        mese_di_riferimento: @mese)
      return exact_scope if exact_scope.exists?

      regional_scope(zoning, anno)
    end

    def regional_scope(zoning, anno)
      regional_id = regional_zoning_id(zoning)
      return Import.none if regional_id.nil?

      Import.where(azzonamento_di_riferimento_id: regional_id, anno_di_riferimento: anno,
        mese_di_riferimento: @mese).where("codice_azzonamento_completo LIKE ?", "#{zoning.codice_azzonamento}%")
    end

    def regional_zoning_id(zoning)
      codice = zoning.codice_azzonamento
      return nil if codice.blank? || codice.length <= 1

      Zoning.find_by(codice_azzonamento: codice[0])&.id
    end

    def build_result
      row = build_row(@zoning)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        count_anno: row.count_anno, count_precedente: row.count_precedente, diff: row.diff,
        diff_percent: row.diff_percent, comprensori: comprensori)
    end

    def build_row(zoning)
      count_anno = count_for(zoning, @anno)
      count_precedente = count_for(zoning, @anno_precedente)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(zoning:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    # Quando l'azzonamento scelto è regionale (codice a lettera singola, es.
    # "G"), aggiunge una riga per ciascuna provincia (es. "GA", "GB", ...).
    def comprensori
      return [] unless regionale?

      province_zonings.map { |zoning| build_row(zoning) }
    end

    def regionale?
      @zoning.codice_azzonamento.to_s.length == 1
    end

    def province_zonings
      Zoning.where("codice_azzonamento LIKE ? AND codice_azzonamento != ?", "#{@zoning.codice_azzonamento}%",
        @zoning.codice_azzonamento).order(:codice_azzonamento)
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
