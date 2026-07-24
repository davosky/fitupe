module Statistics
  # Conta le pratiche Provvisorie (provvisoria = "SI") e le Revoche
  # (motivo_cessazione_iscrizione = "Revoca") nell'anno corrente, senza
  # confronto con l'anno precedente. Riusa lo stesso fallback
  # sull'azzonamento superiore di ZoningPeriodScope.
  class ProvisionalRevocationBreakdown
    Row = Struct.new(:tipologia, :count, :percentuale, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, mese:)
      @zoning = zoning
      @anno = anno
      @mese = mese
    end

    def call
      [
        build_row("Provvisorie", scope.where(provvisoria: "SI").count),
        build_row("Revoche", scope.where(motivo_cessazione_iscrizione: "Revoca").count)
      ]
    end

    private

    def build_row(tipologia, count)
      percentuale = totale_iscritti.zero? ? nil : (count.to_f / totale_iscritti * 100)

      Row.new(tipologia:, count:, percentuale:)
    end

    def totale_iscritti
      @totale_iscritti ||= scope.count
    end

    def scope
      @scope ||= ZoningPeriodScope.call(zoning: @zoning, anno: @anno, mese: @mese)
    end
  end
end
