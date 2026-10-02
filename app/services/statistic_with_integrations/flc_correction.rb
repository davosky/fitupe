module StatisticWithIntegrations
  # L'Anagrafe FLC (IntegrationFlc, un valore per provincia/anno/mese) traccia
  # iscritti FLC aggiuntivi rispetto a quelli già presenti in SinCGIL: il
  # valore va sommato (non confrontato/sottratto) al conteggio SinCGIL della
  # categoria FLC per provincia, e di conseguenza al totale iscritti. Lo
  # stesso importo va riportato anche sulla riga "Delega Tesoro" di
  # Tipologie Delega (dall'orchestratore, non da questa classe).
  #
  # Il dato di un mese si applica alle statistiche dello STESSO mese (es. il
  # record di Luglio integra le statistiche di Luglio): nessuno sfasamento.
  class FlcCorrection
    Row = Struct.new(:zoning, :anagrafe, :diff, keyword_init: true)
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
      return regional_result if @zoning.regionale?

      return missing_result([ @zoning ]) unless dato_presente?(@zoning)

      rows = [ build_row(@zoning) ]
      Result.new(rows:, total_diff: rows.sum(&:diff))
    end

    private

    # A livello regionale non si blocca mai: si integrano le province per cui
    # esiste il dato Anagrafe FLC e si lasciano invariate (nessuna riga, quindi
    # nessun diff) quelle prive di integrazione.
    def regional_result
      rows = province_zonings.select { |zoning| dato_presente?(zoning) }.map { |zoning| build_row(zoning) }
      Result.new(rows:, total_diff: rows.sum(&:diff))
    end

    def dato_presente?(zoning) = IntegrationFlc.exists?(zoning:, year: @anno, month: @mese)

    def province_zonings = Zoning.comprensori_di(@zoning)

    def build_row(zoning)
      anagrafe = IntegrationFlc.find_by(zoning:, year: @anno, month: @mese).subscribers_af
      Row.new(zoning:, anagrafe:, diff: anagrafe)
    end

    def missing_result(missing)
      Result.new(error: "Non ci sono dati Anagrafe FLC per #{@mese} #{@anno} in " \
        "#{missing.map(&:descrizione_azzonamento).join(', ')}.")
    end
  end
end
