module StatisticWithIntegrations
  # Confronta il totale iscritti Cassa Edile (IntegrationFillea, un valore per
  # provincia/anno) con il conteggio SinCGIL dei lavoratori con
  # tipologia_delega "Ordinaria Cassa Edile" nello stesso periodo. La
  # differenza è ciò che va sommato al totale iscritti reale della provincia.
  # Quando lo zoning scelto è regionale, calcola una riga per ciascuna
  # provincia figlia (stesso pattern di Statistics::TotalMembersComparison).
  class FilleaCorrection
    Row = Struct.new(:zoning, :cassa_edile, :sincgil, :diff, keyword_init: true)
    Result = Struct.new(:rows, :total_diff, :error, keyword_init: true) do
      def success? = error.blank?
    end

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      missing = target_zonings.reject { |zoning| IntegrationFillea.exists?(zoning:, year: @anno) }
      return missing_result(missing) if missing.any?

      rows = target_zonings.map { |zoning| build_row(zoning) }
      Result.new(rows:, total_diff: rows.sum(&:diff))
    end

    private

    def target_zonings
      regionale? ? province_zonings : [ @zoning ]
    end

    def regionale? = @zoning.codice_azzonamento.to_s.length == 1

    def province_zonings
      Zoning.where("codice_azzonamento LIKE ? AND codice_azzonamento != ?",
        "#{@zoning.codice_azzonamento}%", @zoning.codice_azzonamento).order(:codice_azzonamento)
    end

    def build_row(zoning)
      cassa_edile = IntegrationFillea.find_by(zoning:, year: @anno).subscribers_ce
      sincgil = Statistics::ZoningPeriodScope.call(zoning:, anno: @anno, mese: @mese)
        .where(tipologia_delega: Statistics::DelegationTypeBreakdown::TIPOLOGIE.fetch("Ordinaria C.E.")).count

      Row.new(zoning:, cassa_edile:, sincgil:, diff: cassa_edile - sincgil)
    end

    def missing_result(missing)
      Result.new(error: "Non ci sono dati Cassa Edile per il #{@anno} " \
        "nell'azzonamento #{missing.map(&:descrizione_azzonamento).join(', ')}.")
    end
  end
end
