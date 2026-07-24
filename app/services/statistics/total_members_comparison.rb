module Statistics
  class TotalMembersComparison
    Result = Struct.new(:zoning, :mese, :anno, :anno_precedente, :count_anno, :count_precedente, :diff,
      :diff_percent, :comprensori, :categorie, :attivi_pensionati, :tipologie_iscrizione, :tipologie_delega,
      :nazionalita, :error, keyword_init: true) do
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

    def scope_for(zoning, anno)
      ZoningPeriodScope.call(zoning:, anno:, mese: @mese)
    end

    def build_result
      row = build_row(@zoning)

      Result.new(zoning: @zoning, mese: @mese, anno: @anno, anno_precedente: @anno_precedente,
        count_anno: row.count_anno, count_precedente: row.count_precedente, diff: row.diff,
        diff_percent: row.diff_percent, comprensori: comprensori, categorie: categorie,
        attivi_pensionati: attivi_pensionati, tipologie_iscrizione: tipologie_iscrizione,
        tipologie_delega: tipologie_delega, nazionalita: nazionalita)
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

    def categorie
      CategoryBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def attivi_pensionati
      EmploymentStatusBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def tipologie_iscrizione
      MembershipTypeBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def tipologie_delega
      DelegationTypeBreakdown.call(zoning: @zoning, anno: @anno, anno_precedente: @anno_precedente, mese: @mese)
    end

    def nazionalita
      NationalityBreakdown.call(zoning: @zoning, anno: @anno, mese: @mese)
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
