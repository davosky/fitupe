module StatisticWithIntegrations
  # L'Anagrafe FLC (IntegrationFlc, un valore per provincia/anno/mese) traccia
  # iscritti FLC aggiuntivi rispetto a quelli già presenti in SinCGIL: il
  # valore va sommato (non confrontato/sottratto) al conteggio SinCGIL della
  # categoria FLC per provincia, e di conseguenza al totale iscritti. Lo
  # stesso importo va riportato anche sulla riga "Delega Tesoro" di
  # Tipologie Delega (dall'orchestratore, non da questa classe).
  #
  # Il dato di un mese si applica alle statistiche del mese SUCCESSIVO (es.
  # il record di Maggio integra le statistiche di Giugno), per via del ritardo
  # con cui l'Anagrafe FLC rende disponibili i dati.
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
      return regional_result if regionale?

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

    def dato_presente?(zoning) = IntegrationFlc.exists?(zoning:, year: lookup_year, month: lookup_month)

    def regionale? = @zoning.codice_azzonamento.to_s.length == 1

    def province_zonings
      Zoning.where("codice_azzonamento LIKE ? AND codice_azzonamento != ?",
        "#{@zoning.codice_azzonamento}%", @zoning.codice_azzonamento).order(:codice_azzonamento)
    end

    def lookup_month
      # indice -1 (Gennaio) restituisce naturalmente "Dicembre" per via
      # dell'indicizzazione negativa di Ruby sugli array
      ImportForm::MESI[ImportForm::MESI.index(@mese) - 1]
    end

    def lookup_year
      ImportForm::MESI.index(@mese).zero? ? (@anno.to_i - 1).to_s : @anno
    end

    def build_row(zoning)
      anagrafe = IntegrationFlc.find_by(zoning:, year: lookup_year, month: lookup_month).subscribers_af
      Row.new(zoning:, anagrafe:, diff: anagrafe)
    end

    def missing_result(missing)
      Result.new(error: "Non ci sono dati Anagrafe FLC per #{lookup_month} #{lookup_year} in " \
        "#{missing.map(&:descrizione_azzonamento).join(', ')}.")
    end
  end
end
